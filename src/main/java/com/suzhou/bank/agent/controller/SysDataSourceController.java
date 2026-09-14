package com.suzhou.bank.agent.controller;

import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.util.AgentQueryGenerator;
import com.suzhou.bank.agent.db.DataSourceCachePool;
import com.suzhou.bank.agent.model.req.IndexTableSyncRcordReq;
import com.suzhou.bank.agent.model.req.TableSyncRcordReq;
import com.suzhou.bank.agent.model.vo.IndexParamsVO;
import com.suzhou.bank.agent.entity.SysDataSource;
import com.suzhou.bank.agent.model.req.DataSourceDataPreviewReq;
import com.suzhou.bank.agent.model.req.ParamsDataSourceDataPreviewReq;
import com.suzhou.bank.agent.model.req.TableInfoQueryReq;
import com.suzhou.bank.agent.model.req.TableListQueryReq;
import com.suzhou.bank.agent.service.ISysDataSourceService;
import com.suzhou.bank.agent.util.SecurityUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.ModelAndView;

import java.util.Arrays;
import java.util.Date;
import java.util.List;
import java.util.Objects;

@Slf4j
@Tag(name = "多数据源管理")
@RestController
// 迁移改造点：路径加 /api/agent 前缀（源工程为 "/sys/dataSource"）。
// 两个原因：① 宿主 AuthInterceptor 只拦 /api/**，不加前缀则该接口完全无鉴权；
//           ② 前端 agent 模块的 axios baseURL 是 /api，不加前缀会 404。
@RequestMapping("/api/agent/sys/dataSource")
public class SysDataSourceController {

    @Autowired
    private ISysDataSourceService sysDataSourceService;

    @GetMapping(value = "/list")
    public AgentResult<?> queryPageList(SysDataSource sysDataSource, @RequestParam(name = "pageNo", defaultValue = "1") Integer pageNo, @RequestParam(name = "pageSize", defaultValue = "10") Integer pageSize, HttpServletRequest req) {
        QueryWrapper<SysDataSource> queryWrapper = AgentQueryGenerator.initQueryWrapper(sysDataSource, req.getParameterMap());
        Page<SysDataSource> page = new Page<>(pageNo, pageSize);
        IPage<SysDataSource> pageList = sysDataSourceService.page(page, queryWrapper);
        List<SysDataSource> records = pageList.getRecords();
        records.forEach(item -> {
            String dbPassword = item.getDbPassword();
            if (StringUtils.isNotBlank(dbPassword)) {
                String decodedStr = SecurityUtil.jiemi(dbPassword);
                item.setDbPassword(decodedStr);
            }
        });
        return AgentResult.OK(pageList);
    }

    @GetMapping(value = "/options")
    public AgentResult<?> queryOptions(SysDataSource sysDataSource, HttpServletRequest req) {
        QueryWrapper<SysDataSource> queryWrapper = AgentQueryGenerator.initQueryWrapper(sysDataSource, req.getParameterMap());
        List<SysDataSource> pageList = sysDataSourceService.list(queryWrapper);
        JSONArray array = new JSONArray(pageList.size());
        for (SysDataSource item : pageList) {
            JSONObject option = new JSONObject(3);
            option.put("value", item.getCode());
            option.put("label", item.getName());
            option.put("text", item.getName());
            array.add(option);
        }
        return AgentResult.OK(array);
    }

    @PostMapping(value = "/add")
    public AgentResult<?> add(@RequestBody SysDataSource sysDataSource) {
        try {
            String dbPassword = sysDataSource.getDbPassword();
            if (StringUtils.isNotBlank(dbPassword)) {
                String encrypt = SecurityUtil.jiami(dbPassword);
                sysDataSource.setDbPassword(encrypt);
            }
            sysDataSourceService.save(sysDataSource);
        } catch (Exception e) {
            throw new AgentBizException("添加失败！");
        }
        return AgentResult.OK("添加成功！");
    }

    @PostMapping(value = "/edit")
    public AgentResult<?> edit(@RequestBody SysDataSource sysDataSource) {
        try {
            SysDataSource d = sysDataSourceService.getById(sysDataSource.getId());
            DataSourceCachePool.removeCache(d.getCode());
            String dbPassword = sysDataSource.getDbPassword();
            if (StringUtils.isNotBlank(dbPassword)) {
                String encrypt = SecurityUtil.jiami(dbPassword);
                sysDataSource.setDbPassword(encrypt);
            }
            sysDataSource.setUpdateTime(new Date());
            sysDataSourceService.updateById(sysDataSource);
        } catch (Exception e) {
            log.error("编辑数据源失败", e);
        }
        return AgentResult.OK("编辑成功!");
    }

    @GetMapping(value = "/delete")
    public AgentResult<?> delete(@RequestParam(name = "id") String id) {
        SysDataSource sysDataSource = sysDataSourceService.getById(id);
        DataSourceCachePool.removeCache(sysDataSource.getCode());
        sysDataSourceService.removeById(id);
        return AgentResult.OK("删除成功!");
    }

    @GetMapping(value = "/deleteBatch")
    public AgentResult<?> deleteBatch(@RequestParam(name = "ids") String ids) {
        List<String> idList = Arrays.asList(ids.split(","));
        idList.forEach(item -> {
            SysDataSource sysDataSource = sysDataSourceService.getById(item);
            if (Objects.nonNull(sysDataSource)) {
                DataSourceCachePool.removeCache(sysDataSource.getCode());
            }
        });
        this.sysDataSourceService.removeByIds(idList);
        return AgentResult.OK("批量删除成功！");
    }

    @GetMapping(value = "/queryById")
    public AgentResult<?> queryById(@RequestParam(name = "id") String id) {
        SysDataSource sysDataSource = sysDataSourceService.getById(id);
        return AgentResult.OK(sysDataSource);
    }

    @PostMapping(value = "/getSyncTableList", name = "数据源表信息列表", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> getSyncTableList(@RequestBody TableListQueryReq tableListQueryReq) {
        return AgentResult.OK(sysDataSourceService.getSyncTableList(tableListQueryReq));
    }

    @PostMapping(value = "/getSyncTabInfo", name = "数据源表详情查询接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> getSyncTabInfo(@RequestBody TableInfoQueryReq tableInfoQueryReq) {
        return AgentResult.OK(sysDataSourceService.getSyncTableInfo(tableInfoQueryReq));
    }

    @PostMapping(value = "/dataPreviewList", name = "数据预览查询接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryDataPreviewList(@RequestBody DataSourceDataPreviewReq dataSourceDataPreviewReq) {
        return sysDataSourceService.getDataPreview(dataSourceDataPreviewReq);
    }

    @PostMapping(value = "/sqlPreviewList", name = "sql查询结果预览", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> sqlPreviewList(@RequestBody DataSourceDataPreviewReq dataSourceDataPreviewReq) {
        return sysDataSourceService.sqlPreviewList(dataSourceDataPreviewReq);
    }

    @PostMapping(value = "/paramDataSourcePreviewList", name = "指标数据源预览查询接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryParamDataSourcePreviewList(@RequestBody ParamsDataSourceDataPreviewReq paramsDataSourceDataPreviewReq) {
        return sysDataSourceService.getParamDataSourcePreview(paramsDataSourceDataPreviewReq);
    }

    @PostMapping(value = "/showParam", name = "指标快速引入默认根据表名预处理指标名称", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> showParamInfo(@RequestBody IndexTableSyncRcordReq reqMsg) {
        return sysDataSourceService.showParamInfo(reqMsg);
    }

    @PostMapping(value = "/quickQueryParam", name = "快速指标引入表字段映射指标列表接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> queryParamFromSourceTableField(@RequestBody TableSyncRcordReq reqMsg) {
        return sysDataSourceService.querySourceTableField(reqMsg);
    }

    @PostMapping(value = "/addQuickParam", name = "快速指标引入表字段映射指标保存接口", produces = MediaType.APPLICATION_JSON_VALUE)
    public AgentResult<?> saveIndexParamsFromSourceTableField(@RequestBody List<IndexParamsVO> reqMsg) {
        return sysDataSourceService.saveIndexParamsFromSourceTableField(reqMsg);
    }

    // ===== 迁移说明：以下两个接口刻意未迁移 =====
    // 源实现的 /exportXls（导出 Excel）与 /importExcel（导入 Excel）都靠 JeecgBoot 的
    // JeecgController 基类 + autopoi 实现：前者要 ExcelExportHandler 做样式导出，
    // 后者要 ImportParams / ExcelImportUtil 做模板解析。
    // 这两条链路与「数据源管理」的核心能力（配置数据源、查表元数据、SQL/数据预览、快速引入）
    // 无关，且会额外引入 autopoi 一整套依赖；前端数据源管理页面也未使用。
    // 若后续确需导入导出，建议用宿主已有的 EasyExcel/POI 重写，而不是搬 Jeecg 的那套。
}
