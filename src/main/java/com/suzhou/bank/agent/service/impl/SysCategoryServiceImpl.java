package com.suzhou.bank.agent.service.impl;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.model.vo.SysCategoryModel;
import com.suzhou.bank.agent.util.OConvertUtils;
import com.suzhou.bank.agent.enums.YesOrNoEnum;
import com.suzhou.bank.agent.mapper.SysCategoryMapper;
import com.suzhou.bank.agent.model.vo.TreeSelectModel;
import com.suzhou.bank.agent.entity.SysCategory;
import com.suzhou.bank.agent.service.ISysCategoryService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * @Description: 分类字典
 * @Author: jeecg-boot
 * @Date: 2019-05-29
 * @Version: V1.0
 */
@Service
public class SysCategoryServiceImpl extends ServiceImpl<SysCategoryMapper, SysCategory> implements ISysCategoryService {

    @Override
    public void addSysCategory(SysCategory sysCategory) {
        String categoryPid = ISysCategoryService.ROOT_PID_VALUE;
        if (OConvertUtils.isNotEmpty(sysCategory.getPid())) {
            categoryPid = sysCategory.getPid();

            // PID 不是根节点 说明需要设置父节点 hasChild 为1
            if (!ISysCategoryService.ROOT_PID_VALUE.equals(categoryPid)) {
                SysCategory parent = baseMapper.selectById(categoryPid);
                if (parent != null && !"1".equals(parent.getHasChild())) {
                    parent.setHasChild("1");
                    baseMapper.updateById(parent);
                }
            }
        }
        // ===== 迁移改造点：填值规则改本地兜底（这是本类唯一的行为差异，务必知悉） =====
        // 源实现：categoryCode = (String) FillRuleUtil.executeRule(FillRuleConstant.CATEGORY, formData);
        //   即走 Jeecg 的「填值规则」——查 sys_fill_rule 表拿到 ruleClass，再反射 new 出
        //   IFillRuleHandler 实现类执行。本工程不引入这套地基（要建表 + 搬 handler + 反射），故降级为：
        //     ① 前端显式传了 code  → 直接沿用（这是相对原实现的**增强**：原实现会无条件用规则结果覆盖传入值）
        //     ② 未传              → 按「父节点 code + 3 位序号」生成
        // 风险：若行内的填值规则口径与此不同，自动生成的分类编码会与预期不符。
        //   但 code 是业务硬编码引用的（如 B05 / B06A01），实际使用中应由配置方显式指定，
        //   自动生成只是兜底。建议向公司索取「分类字典填值规则」定义后替换本方法。
        String categoryCode = StringUtils.isNotEmpty(sysCategory.getCode())
                ? sysCategory.getCode()
                : generateCategoryCode(categoryPid);
        sysCategory.setCode(categoryCode);
        sysCategory.setPid(categoryPid);
        baseMapper.insert(sysCategory);
    }

    /**
     * 生成分类编码（本地兜底实现，替代 Jeecg 的填值规则）
     *
     * <p>规则：{@code 父节点 code + 3 位递增序号}；根节点（{@code pid=0}）无前缀，直接产 3 位序号。
     * 序号取同级已有 code 的最大数值后缀 +1，非数字后缀（如 {@code B06A01} 的 {@code A01}）不参与推断。</p>
     */
    private String generateCategoryCode(String pid) {
        String prefix = "";
        if (!ISysCategoryService.ROOT_PID_VALUE.equals(pid)) {
            SysCategory parent = baseMapper.selectById(pid);
            if (parent != null && StringUtils.isNotEmpty(parent.getCode())) {
                prefix = parent.getCode();
            }
        }
        LambdaQueryWrapper<SysCategory> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SysCategory::getPid, pid);
        wrapper.select(SysCategory::getCode);
        List<SysCategory> siblings = baseMapper.selectList(wrapper);
        int max = 0;
        for (SysCategory sibling : siblings) {
            String code = sibling.getCode();
            if (StringUtils.isEmpty(code) || code.length() <= prefix.length()) {
                continue;
            }
            try {
                max = Math.max(max, Integer.parseInt(code.substring(prefix.length())));
            } catch (NumberFormatException ignore) {
                // 非数字后缀不参与序号推断，跳过
            }
        }
        return prefix + String.format("%03d", max + 1);
    }

    @Override
    public void updateSysCategory(SysCategory sysCategory) {
        if (OConvertUtils.isEmpty(sysCategory.getPid())) {
            sysCategory.setPid(ISysCategoryService.ROOT_PID_VALUE);
        } else {
            // 如果当前节点父ID不为空 则设置父节点的hasChild 为1
            SysCategory parent = baseMapper.selectById(sysCategory.getPid());
            if (parent != null && !"1".equals(parent.getHasChild())) {
                parent.setHasChild("1");
                baseMapper.updateById(parent);
            }
        }
        baseMapper.updateById(sysCategory);
    }

    @Override
    public List<TreeSelectModel> queryListByCode(String pcode) throws AgentBizException {
        String pid = ROOT_PID_VALUE;
        if (OConvertUtils.isNotEmpty(pcode)) {
            List<SysCategory> list = baseMapper.selectList(new LambdaQueryWrapper<SysCategory>().eq(SysCategory::getCode, pcode).eq(SysCategory::getParamStatus, YesOrNoEnum.Y.name()));
            if (list == null || list.isEmpty()) {
                throw new AgentBizException("该编码【" + pcode + "】不存在，请核实!");
            }
            if (list.size() > 1) {
                throw new AgentBizException("该编码【" + pcode + "】存在多个，请核实!");
            }
            pid = list.get(0).getId();
        }
        return baseMapper.queryListByPid(pid, null);
    }

    @Override
    public List<TreeSelectModel> queryListByPid(String pid) {
        if (OConvertUtils.isEmpty(pid)) {
            pid = ROOT_PID_VALUE;
        }
        return baseMapper.queryListByPid(pid, null);
    }

    @Override
    public List<SysCategoryModel> queryList(String pid) {
        return baseMapper.queryList(pid);
    }

    @Override
    public String queryIdByCode(String code) {
        return baseMapper.queryIdByCode(code);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteSysCategory(String ids) {
        String allIds = this.queryTreeChildIds(ids);
        String pids = this.queryTreePids(ids);
        // 1.删除时将节点下所有子节点一并删除
        this.baseMapper.deleteBatchIds(Arrays.asList(allIds.split(",")));
        // 2.将父节点中已经没有下级的节点，修改为没有子节点
        if (OConvertUtils.isNotEmpty(pids)) {
            LambdaUpdateWrapper<SysCategory> updateWrapper = new UpdateWrapper<SysCategory>().lambda().in(SysCategory::getId, Arrays.asList(pids.split(","))).set(SysCategory::getHasChild, "0");
            this.update(updateWrapper);
        }
    }

    /**
     * 查询节点下所有子节点
     *
     * @param ids
     * @return
     */
    private String queryTreeChildIds(String ids) {
        // 获取id数组
        String[] idArr = ids.split(",");
        StringBuffer sb = new StringBuffer();
        for (String pidVal : idArr) {
            if (pidVal != null) {
                if (!sb.toString().contains(pidVal)) {
                    if (sb.toString().length() > 0) {
                        sb.append(",");
                    }
                    sb.append(pidVal);
                    this.getTreeChildIds(pidVal, sb);
                }
            }
        }
        return sb.toString();
    }

    /**
     * 查询需修改标识的父节点ids
     *
     * @param ids
     * @return
     */
    private String queryTreePids(String ids) {
        StringBuffer sb = new StringBuffer();
        // 获取id数组
        String[] idArr = ids.split(",");
        for (String id : idArr) {
            if (id != null) {
                SysCategory category = this.baseMapper.selectById(id);
                // 根据id查询pid值
                String metaPid = category.getPid();
                // 查询此节点上一级是否还有其他子节点
                LambdaQueryWrapper<SysCategory> queryWrapper = new LambdaQueryWrapper<>();
                queryWrapper.eq(SysCategory::getPid, metaPid);
                queryWrapper.notIn(SysCategory::getId, Arrays.asList(idArr));
                List<SysCategory> dataList = this.baseMapper.selectList(queryWrapper);
                if ((dataList == null || dataList.size() == 0) && !Arrays.asList(idArr).contains(metaPid) && !sb.toString().contains(metaPid)) {
                    // 如果当前节点原本有子节点 现在木有了，更新状态
                    sb.append(metaPid).append(",");
                }
            }
        }
        if (sb.toString().endsWith(",")) {
            sb = sb.deleteCharAt(sb.length() - 1);
        }
        return sb.toString();
    }

    /**
     * 递归 根据父id获取子节点id
     *
     * @param pidVal
     * @param sb
     * @return
     */
    private StringBuffer getTreeChildIds(String pidVal, StringBuffer sb) {
        LambdaQueryWrapper<SysCategory> queryWrapper = new LambdaQueryWrapper<>();
        queryWrapper.eq(SysCategory::getPid, pidVal);
        List<SysCategory> dataList = baseMapper.selectList(queryWrapper);
        if (dataList != null && dataList.size() > 0) {
            for (SysCategory category : dataList) {
                if (!sb.toString().contains(category.getId())) {
                    sb.append(",").append(category.getId());
                }
                this.getTreeChildIds(category.getId(), sb);
            }
        }
        return sb;
    }

    @Override
    public List<String> loadDictItem(String ids) {
        return this.loadDictItem(ids, true);
    }

    @Override
    public List<String> loadDictItem(String ids, boolean delNotExist) {
        String[] idArray = ids.split(",");
        LambdaQueryWrapper<SysCategory> query = new LambdaQueryWrapper<>();
        query.in(SysCategory::getId, Arrays.asList(idArray));
        // 查询数据
        List<SysCategory> list = super.list(query);
        // 取出name并返回
        List<String> textList;
        if (delNotExist) {
            textList = list.stream().map(SysCategory::getName).collect(Collectors.toList());
        } else {
            textList = new ArrayList<>();
            for (String id : idArray) {
                List<SysCategory> res = list.stream().filter(i -> id.equals(i.getId())).collect(Collectors.toList());
                textList.add(res.size() > 0 ? res.get(0).getName() : id);
            }
        }
        return textList;
    }

    @Override
    public boolean doubleCheckDictCode(String id, String pid, String paramValue) {
        LambdaQueryWrapper<SysCategory> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.ne(StringUtils.isNotEmpty(id), SysCategory::getId, id);
        queryWrapper.eq(SysCategory::getPid, pid);
        queryWrapper.eq(SysCategory::getParamValue, paramValue);
        return !list(queryWrapper).isEmpty();
    }

}
