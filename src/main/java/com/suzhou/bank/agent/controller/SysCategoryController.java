package com.suzhou.bank.agent.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.util.AgentQueryGenerator;
import com.suzhou.bank.agent.dict.DictModel;
import com.suzhou.bank.agent.util.OConvertUtils;
import com.suzhou.bank.agent.enums.OnlineEnum;
import com.suzhou.bank.agent.model.vo.TreeSelectModel;
import com.suzhou.bank.agent.entity.SysCategory;
import com.suzhou.bank.agent.service.ISysCategoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.MultipartHttpServletRequest;

import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

/**
 * @Description: 分类字典
 * @Author: jeecg-boot
 * @Date: 2019-05-29
 * @Version: V1.0
 */
@RestController
// 迁移改造点：路径加 /api/agent 前缀（源工程为 "/sys/category"）。
// 两个原因：① 宿主 AuthInterceptor 只拦 /api/**，不加前缀则该接口完全无鉴权；
//           ② 前端 agent 模块的 axios baseURL 是 /api，不加前缀会 404。
@RequestMapping("/api/agent/sys/category")
@Slf4j
public class SysCategoryController {

    @Autowired
    private ISysCategoryService sysCategoryService;


    @GetMapping(value = "/rootList")
    public AgentResult<IPage<SysCategory>> queryPageList(SysCategory sysCategory, @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo, @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        if (OConvertUtils.isEmpty(sysCategory.getPid()) && StringUtils.isEmpty(sysCategory.getName()) && StringUtils.isEmpty(sysCategory.getKeyWord()) && StringUtils.isEmpty(sysCategory.getHitIndependently())) {
            sysCategory.setPid("0");
        }
        AgentResult<IPage<SysCategory>> result = new AgentResult<>();
        QueryWrapper<SysCategory> queryWrapper = new QueryWrapper<>();
        if (StringUtils.isNotEmpty(sysCategory.getPid())) {
            queryWrapper.eq("pid", sysCategory.getPid());
        }
        if (StringUtils.isNotEmpty(sysCategory.getName())) {
            queryWrapper.like("name", sysCategory.getName());
        }
        if (StringUtils.isNotEmpty(sysCategory.getKeyWord())) {
            queryWrapper.like("key_word", sysCategory.getKeyWord());
        }
        if (StringUtils.isNotEmpty(sysCategory.getHitIndependently())) {
            queryWrapper.like("hit_independently", sysCategory.getHitIndependently());
        }
        queryWrapper.orderByDesc("create_time");

        Page<SysCategory> page = new Page<>(pageNo, pageSize);
        IPage<SysCategory> pageList = sysCategoryService.page(page, queryWrapper);
        result.setSuccess(true);
        result.setResult(pageList);
        return result;
    }

    @GetMapping(value = "/childList")
    public AgentResult<List<SysCategory>> queryPageList(SysCategory sysCategory, HttpServletRequest req) {
        AgentResult<List<SysCategory>> result = new AgentResult<List<SysCategory>>();
        QueryWrapper<SysCategory> queryWrapper = AgentQueryGenerator.initQueryWrapper(sysCategory, req.getParameterMap());
        List<SysCategory> list = sysCategoryService.list(queryWrapper);
        result.setSuccess(true);
        result.setResult(list);
        return result;
    }


    @PostMapping(value = "/add")
    public AgentResult<SysCategory> add(@RequestBody SysCategory sysCategory) {
        AgentResult<SysCategory> result = new AgentResult<>();
        try {
            // 先判断编码是否存在
            if (sysCategoryService.doubleCheckDictCode(sysCategory.getId(), sysCategory.getPid(), sysCategory.getParamValue())) {
                log.error("新增分类编码重复！编码信息:[{}-{}]", sysCategory.getPid(), sysCategory.getParamValue());
                return result.error500("新增失败！同一个分类下，参数值不能重复重复！");
            }
            sysCategoryService.addSysCategory(sysCategory);
            result.success("添加成功！");
            return result;
        } catch (Exception e) {
            log.error(e.getMessage(), e);
            return result.error500("操作失败");
        }
    }

    @PutMapping(value = "/edit")
    public AgentResult<SysCategory> edit(@RequestBody SysCategory sysCategory) {
        AgentResult<SysCategory> result = new AgentResult<>();
        SysCategory sysCategoryEntity = sysCategoryService.getById(sysCategory.getId());
        if (sysCategoryEntity == null) {
            result.error500("未找到对应实体");
        } else {
            // 先判断编码是否存在
            if (sysCategoryService.doubleCheckDictCode(sysCategoryEntity.getId(), sysCategory.getPid(), sysCategory.getParamValue())) {
                log.error("编辑分类编码重复！编码信息:[{}-{}]", sysCategory.getCode(), sysCategory.getParamValue());
                return result.error500("更新失败！同一个分类下，参数值不能重复重复！");
            }
            sysCategoryService.updateSysCategory(sysCategory);
            result.success("修改成功!");
        }
        return result;
    }

    @DeleteMapping(value = "/delete")
    public AgentResult<SysCategory> delete(@RequestParam(name = "id", required = true) String id) {
        AgentResult<SysCategory> result = new AgentResult<SysCategory>();
        SysCategory sysCategory = sysCategoryService.getById(id);
        if (sysCategory == null) {
            result.error500("未找到对应实体");
        } else {
            this.sysCategoryService.deleteSysCategory(id);
            result.success("删除成功!");
        }
        return result;
    }

    /**
     * 批量删除
     *
     * @param ids
     * @return
     */
    @DeleteMapping(value = "/deleteBatch")
    public AgentResult<SysCategory> deleteBatch(@RequestParam(name = "ids", required = true) String ids) {
        AgentResult<SysCategory> result = new AgentResult<SysCategory>();
        if (ids == null || "".equals(ids.trim())) {
            result.error500("参数不识别！");
        } else {
            this.sysCategoryService.deleteSysCategory(ids);
            result.success("删除成功!");
        }
        return result;
    }

    /**
     * 通过id查询
     *
     * @param id
     * @return
     */
    @GetMapping(value = "/queryById")
    public AgentResult<SysCategory> queryById(@RequestParam(name = "id", required = true) String id) {
        AgentResult<SysCategory> result = new AgentResult<SysCategory>();
        SysCategory sysCategory = sysCategoryService.getById(id);
        if (sysCategory == null) {
            result.error500("未找到对应实体");
        } else {
            result.setResult(sysCategory);
            result.setSuccess(true);
        }
        return result;
    }

    // ===== 迁移说明：以下两个接口刻意未迁移 =====
    // 源实现的 /exportXls（Excel 导出）依赖 Jeecg 的 ExcelExportHandler，
    // /importExcel（Excel 导入）依赖 autopoi 的 ImportParams。
    // 这两条链路与「分类字典」的核心能力（树查询、增删改）无关，且会引入 autopoi 依赖（宿主没有）；
    // 前端指标配置页面只用到 loadTreeRoot / loadTreeData / loadDictItem 等查询接口，未使用导入导出。
    // 若后续确需该功能，建议用宿主已有的 POI/EasyExcel 重写，而不是搬 Jeecg 那一套。


    /**
     * 加载单个数据 用于回显
     */
    @RequestMapping(value = "/loadOne", method = RequestMethod.GET)
    public AgentResult<SysCategory> loadOne(@RequestParam(name = "field") String field, @RequestParam(name = "val") String val) {
        AgentResult<SysCategory> result = new AgentResult<SysCategory>();
        try {

            QueryWrapper<SysCategory> query = new QueryWrapper<SysCategory>();
            query.eq(field, val);
            List<SysCategory> ls = this.sysCategoryService.list(query);
            if (ls == null || ls.size() == 0) {
                result.setMessage("查询无果");
                result.setSuccess(false);
            } else if (ls.size() > 1) {
                result.setMessage("查询数据异常,[" + field + "]存在多个值:" + val);
                result.setSuccess(false);
            } else {
                result.setSuccess(true);
                result.setResult(ls.get(0));
            }
        } catch (Exception e) {
            log.error("查询失败", e);
            result.setMessage("查询失败，请稍后再试");
            result.setSuccess(false);
        }
        return result;
    }

    /**
     * 加载节点的子数据
     */
    @RequestMapping(value = "/loadTreeChildren", method = RequestMethod.GET)
    public AgentResult<List<TreeSelectModel>> loadTreeChildren(@RequestParam(name = "pid") String pid) {
        AgentResult<List<TreeSelectModel>> result = new AgentResult<List<TreeSelectModel>>();
        try {
            List<TreeSelectModel> ls = this.sysCategoryService.queryListByPid(pid);
            result.setResult(ls);
            result.setSuccess(true);
        } catch (Exception e) {
            log.error("加载子节点失败", e);
            result.setMessage("加载失败，请稍后再试");
            result.setSuccess(false);
        }
        return result;
    }

    /**
     * 加载一级节点/如果是同步 则所有数据
     */
    @RequestMapping(value = "/loadTreeRoot", method = RequestMethod.GET)
    public AgentResult<List<TreeSelectModel>> loadTreeRoot(@RequestParam(name = "async") Boolean async, @RequestParam(name = "pcode") String pcode) {
        AgentResult<List<TreeSelectModel>> result = new AgentResult<List<TreeSelectModel>>();
        try {
            List<TreeSelectModel> ls = this.sysCategoryService.queryListByCode(pcode);
            if (!async) {
                loadAllCategoryChildren(ls);
            }
            result.setResult(ls);
            result.setSuccess(true);
        } catch (Exception e) {
            log.error("加载根节点失败", e);
            result.setMessage("加载失败，请稍后再试");
            result.setSuccess(false);
        }
        return result;
    }

    /**
     * 递归求子节点 同步加载用到
     */
    private void loadAllCategoryChildren(List<TreeSelectModel> ls) {
        for (TreeSelectModel tsm : ls) {
            List<TreeSelectModel> temp = this.sysCategoryService.queryListByPid(tsm.getKey());
            if (temp != null && temp.size() > 0) {
                tsm.setChildren(temp);
                loadAllCategoryChildren(temp);
            }
        }
    }

    /**
     * 校验编码
     *
     * @param pid
     * @param code
     * @return
     */
    @GetMapping(value = "/checkCode")
    public AgentResult<?> checkCode(@RequestParam(name = "pid", required = false) String pid, @RequestParam(name = "code", required = false) String code) {
        if (OConvertUtils.isEmpty(code)) {
            return AgentResult.error("错误,类型编码为空!");
        }
        if (OConvertUtils.isEmpty(pid)) {
            return AgentResult.OK();
        }
        SysCategory parent = this.sysCategoryService.getById(pid);
        if (code.startsWith(parent.getCode())) {
            return AgentResult.OK();
        } else {
            return AgentResult.error("编码不符合规范,须以\"" + parent.getCode() + "\"开头!");
        }

    }


    /**
     * 分类字典树控件 加载节点
     *
     * @param pid
     * @param pcode
     * @param condition
     * @return
     */
    @RequestMapping(value = "/loadTreeData", method = RequestMethod.GET)
    public AgentResult<List<TreeSelectModel>> loadDict(@RequestParam(name = "pid", required = false) String pid, @RequestParam(name = "pcode", required = false) String pcode, @RequestParam(name = "condition", required = false) String condition) {
        AgentResult<List<TreeSelectModel>> result = new AgentResult<List<TreeSelectModel>>();
        // pid如果传值了 就忽略pcode的作用
        if (OConvertUtils.isEmpty(pid)) {
            if (OConvertUtils.isEmpty(pcode)) {
                result.setSuccess(false);
                result.setMessage("加载分类字典树参数有误.[null]!");
                return result;
            } else {
                if (ISysCategoryService.ROOT_PID_VALUE.equals(pcode)) {
                    pid = ISysCategoryService.ROOT_PID_VALUE;
                } else {
                    pid = this.sysCategoryService.queryIdByCode(pcode);
                }
                if (OConvertUtils.isEmpty(pid)) {
                    result.setSuccess(false);
                    result.setMessage("加载分类字典树参数有误.[code]!");
                    return result;
                }
            }
        }
        // condition 动态过滤功能已移除，参数保留用于 API 向后兼容
        List<TreeSelectModel> ls = sysCategoryService.queryListByPid(pid);
        result.setSuccess(true);
        result.setResult(ls);
        return result;
    }

    /**
     * 分类字典控件数据回显[表单页面]
     *
     * @param ids
     * @param delNotExist 是否移除不存在的项，默认为true，设为false如果某个key不存在数据库中，则直接返回key本身
     * @return
     */
    @RequestMapping(value = "/loadDictItem", method = RequestMethod.GET)
    public AgentResult<List<String>> loadDictItem(@RequestParam(name = "ids") String ids, @RequestParam(name = "delNotExist", required = false, defaultValue = "true") boolean delNotExist) {
        AgentResult<List<String>> result = new AgentResult<>();
        // 非空判断
        if (StringUtils.isBlank(ids)) {
            result.setSuccess(false);
            result.setMessage("ids 不能为空");
            return result;
        }
        // 查询数据
        List<String> textList = sysCategoryService.loadDictItem(ids, delNotExist);
        result.setSuccess(true);
        result.setResult(textList);
        return result;
    }

    /**
     * [列表页面]加载分类字典数据 用于值的替换
     *
     * @param code
     * @return
     */
    @RequestMapping(value = "/loadAllData", method = RequestMethod.GET)
    public AgentResult<List<DictModel>> loadAllData(@RequestParam(name = "code", required = true) String code) {
        AgentResult<List<DictModel>> result = new AgentResult<List<DictModel>>();
        LambdaQueryWrapper<SysCategory> query = new LambdaQueryWrapper<SysCategory>();
        if (OConvertUtils.isNotEmpty(code) && !"0".equals(code)) {
            query.likeRight(SysCategory::getCode, code);
        }
        List<SysCategory> list = this.sysCategoryService.list(query);
        if (list == null || list.size() == 0) {
            result.setMessage("无数据,参数有误.[code]");
            result.setSuccess(false);
            return result;
        }
        List<DictModel> rdList = new ArrayList<>();
        for (SysCategory c : list) {
            rdList.add(new DictModel(c.getId(), c.getName()));
        }
        result.setSuccess(true);
        result.setResult(rdList);
        return result;
    }

    /**
     * 根据父级id批量查询子节点
     *
     * @param parentIds
     * @return
     */
    @GetMapping("/getChildListBatch")
    public AgentResult<?> getChildListBatch(@RequestParam("parentIds") String parentIds) {
        try {
            QueryWrapper<SysCategory> queryWrapper = new QueryWrapper<>();
            List<String> parentIdList = Arrays.asList(parentIds.split(","));
            queryWrapper.in("pid", parentIdList);
            List<SysCategory> list = sysCategoryService.list(queryWrapper);
            IPage<SysCategory> pageList = new Page<>(1, 10, list.size());
            pageList.setRecords(list);
            return AgentResult.OK(pageList);
        } catch (Exception e) {
            log.error(e.getMessage(), e);
            return AgentResult.error("批量查询子节点失败！");
        }
    }
}
