package com.suzhou.bank.agent.service.impl;

import cn.hutool.core.bean.BeanUtil;
import cn.hutool.core.date.DateUtil;
import cn.hutool.crypto.digest.MD5;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections.CollectionUtils;
import java.util.ArrayList;
import org.apache.commons.lang3.StringUtils;
import com.suzhou.bank.agent.common.ListResult;
import com.suzhou.bank.agent.common.AgentResult;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.util.UUIDGenerator;
import com.suzhou.bank.agent.config.AgentProperties;
import com.suzhou.bank.agent.config.ApiContext;
import com.suzhou.bank.agent.config.ApiContextModel;
import com.suzhou.bank.agent.entity.IndexBaseGroupEntity;
import com.suzhou.bank.agent.entity.IndexParamsEntity;
import com.suzhou.bank.agent.enums.DataTypeEnum;
import com.suzhou.bank.agent.enums.ParamGroupEnum;
import com.suzhou.bank.agent.enums.ParamTypeEnum;
import com.suzhou.bank.agent.enums.ScriptTypeEnum;
import com.suzhou.bank.agent.model.dto.IndexBaseGroupDTO;
import com.suzhou.bank.agent.model.dto.IndexParamsDTO;
import com.suzhou.bank.agent.model.dto.IndexParamsSimpleDTO;
import com.suzhou.bank.agent.model.req.*;
import com.suzhou.bank.agent.model.vo.IndexBaseGroupVO;
import com.suzhou.bank.agent.service.*;
import com.suzhou.bank.agent.cache.DoubleCache;
import com.suzhou.bank.agent.entity.SysDataSource;
import com.suzhou.bank.agent.util.TreeUtil;
import com.suzhou.bank.agent.service.ISysDataSourceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.util.*;
import java.util.concurrent.Executor;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Slf4j
@Service
public class IndexConfigServiceImpl implements IIndexConfigService {

    @Autowired
    private IIndexParamsService indexParamsService;

    @Autowired
    private IKnowledgeBaseParamsService knowledgeBaseParamsService;

    // 迁移改造点：源工程是裸 @Autowired（依赖容器里恰好存在一个 Executor）。
    // 本工程里若不加限定符，会注入到报告模块的 reportAiAnalysisExecutor（原因见 AgentTaskExecutorConfig），
    // 导致指标任务与报告 AI 分析抢线程、且线程名误导排查。故显式指定 agent 自己的线程池。
    @Autowired
    @Qualifier("agentTaskExecutor")
    private Executor executor;

    @Autowired
    private IIndexBaseGroupService indexBaseGroupService;

    @Autowired
    private IIndexRelateInfoService indexRelateInfoService;

    @Autowired
    private DoubleCache doubleCache;

    /** agent 模块配置：目前用于「角色-指标过滤」开关（见 AgentProperties 的说明） */
    @Autowired
    private AgentProperties agentProperties;

    @Autowired
    private ISysRoleIndexService sysRoleIndexService;

    @Autowired
    private IIndexRelateKnowledgeInfoService indexRelateKnowledgeInfoService;

    @Autowired
    private IIndexRelateIndexInfoService indexRelateIndexInfoService;

    @Autowired
    private ISysDataSourceService sysDataSourceService;

    @Override
    public ListResult<?> queryIndexParamsList(IndexParamQueryReq reqMsg) {
        if (StringUtils.isEmpty(reqMsg.getParentParamNo())) {
            return new ListResult<>(0, 0);
        }
        QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("parentParamNo", reqMsg.getParentParamNo());
        queryWrapper.eq("modelNo", "Public");
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamId()), "paramid", reqMsg.getParamId());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamName()), "paramname", reqMsg.getParamName());
        queryWrapper.orderByDesc("inputtime");
        List<IndexParamsEntity> paramsList = indexParamsService.list(queryWrapper);
        List<IndexParamsEntity> oneAllParams = new ArrayList<>();
        getAllParamsByParentParamNo(paramsList, oneAllParams);
        List<IndexParamsEntity> indexParamsEntityList = TreeUtil.buildTree(oneAllParams, IndexParamsEntity::getParamNo, IndexParamsEntity::getParentParamNo);
        List<IndexParamsDTO> indexParamsDTOList = new ArrayList<>();
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            indexParamsEntityList.forEach(param -> {
                IndexParamsDTO indexParamsDTO = new IndexParamsDTO();
                BeanUtil.copyProperties(param, indexParamsDTO, true);
                indexParamsDTOList.add(indexParamsDTO);
            });
        }
        return new ListResult<>(indexParamsDTOList);
    }

    @Override
    public ListResult<?> getAllIndexParamsList(IndexParamQueryReq reqMsg) {
        List<String> indexIdList = getIndexIdListByRoleId();
        // getIndexIdListByRoleId() 的契约：返回「可见分组编号集合」（**非 null**）。
        // 为空 = 一个分组都没授权 → fail-closed 返回空。
        // ⚠️ 这里**不要**再写成 `agentProperties.isIndexRoleFilterEnabled() && CollectionUtils.isEmpty(indexIdList)`：
        //    放行场景（超管 / 开关关闭 / 取不到角色）已在方法内部归一成"全部启用中的分组"，不再用 null 表达，
        //    否则 `CollectionUtils.isEmpty(null) == true` 又会把"放行"误判成"无授权"，列表直接空白。
        //    （2026-09-15 自测实测踩过：日志里只有一条 selectRoleIdsByUserId，之后没有任何 index_params 的 SQL。）
        if (CollectionUtils.isEmpty(indexIdList)) {
            log.info("当前角色没有任何指标分组授权，指标列表按 fail-closed 返回空");
            return new ListResult<>(0, 0);
        }

        int totalSize = 1;
        List<IndexParamsEntity> records = null;
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamID, IndexParamsEntity::getParamName, IndexParamsEntity::getParamType,
                IndexParamsEntity::getDataMethod, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getInputMethod, IndexParamsEntity::getInputUserID,
                IndexParamsEntity::getUpdateUserID, IndexParamsEntity::getInputTime, IndexParamsEntity::getUpdateTime, IndexParamsEntity::getScript,
                IndexParamsEntity::getScriptType, IndexParamsEntity::getSupplierId, IndexParamsEntity::getIntfNo);
        // 指标编号检索：必须**大小写不敏感**（2026-09-21 修复）
        //   库里 `paramid` 存的是**大写字段名**（ACCOUNTMONTH / ACCOUNTSPAYABLE …，实测 920 行），
        //   而 PG/openGauss 的 `LIKE` 是**大小写敏感**的 ⇒ 用户输小写（accountmonth）永远 0 命中，
        //   看起来就像"检索框坏了"。源工程是 MySQL，`like` 默认不区分大小写，所以那边没暴露这个问题。
        //   → 两边都 LOWER() 后再比，等价于把 MySQL 的默认行为搬过来
        //     （与 `SysDataSourceServiceImpl` 的表名检索同一口径）。
        if (StringUtils.isNotEmpty(reqMsg.getParamId())) {
            queryWrapper.apply("LOWER(paramid) LIKE LOWER({0})", "%" + reqMsg.getParamId() + "%");
        }
        queryWrapper.like(StringUtils.isNotEmpty(reqMsg.getParamName()), IndexParamsEntity::getParamName, reqMsg.getParamName());
        // 数据来源（2026-09-16 新增，前端一直有这个检索框但源工程没有对应字段 → 点了没反应）：
        // 列表「数据来源」列是 `getIndexSource(param)` 运行时拼出来的字符串，库里没有同名列，
        // 因此对**产出它的原始列**做模糊匹配 —— script（SQL 文本 / 数据源 JSON 全在里面）、
        // supplierId、intfNo。这样搜表名、数据源代码、接口编号都能命中，方向与列上展示的内容一致。
        if (StringUtils.isNotEmpty(reqMsg.getIndexSource())) {
            String indexSourceKw = reqMsg.getIndexSource().trim();
            queryWrapper.and(w -> w.like(IndexParamsEntity::getScript, indexSourceKw)
                    .or().like(IndexParamsEntity::getSupplierId, indexSourceKw)
                    .or().like(IndexParamsEntity::getIntfNo, indexSourceKw));
        }
        if (StringUtils.isNotBlank(reqMsg.getParentParamNo())) {
            List<IndexParamsEntity> indexParamsEntities = indexParamsService.selectByParentParamNo(reqMsg.getParentParamNo());
            if (CollectionUtils.isEmpty(indexParamsEntities)) {
                return new ListResult<>(0, 0);
            }
            List<String> collect = indexParamsEntities.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
            queryWrapper.and(qr -> qr.in(IndexParamsEntity::getParentParamNo, collect).or().eq(IndexParamsEntity::getParentParamNo, reqMsg.getParentParamNo()));
        }
        // 「指标ID」检索（2026-09-16 修复）
        // 源语义：`getById(paramNo)` 命中时返回「该指标 + 其同级 + 其下级」，用于"点行定位"。
        // 🔴 原实现的问题：**未命中时没有 else 分支** —— records 保持 null，方法末尾的
        //    `CollectionUtils.isEmpty(records)` 直接返回空列表。于是用户在「指标ID」框里输入
        //    一个**不完整的编号**（模糊检索的用法）时，看到的是"查不到任何数据"，
        //    实际是这条分支把查询整个吞掉了。
        // 修法：精确未命中 → 降级为 LIKE 模糊，并继续走下面的分页查询分支。
        boolean paramNoExactHit = false;
        if (StringUtils.isNotEmpty(reqMsg.getParamNo())) {
            // 查询父节点
            IndexParamsEntity indexParamsEntity = indexParamsService.getById(reqMsg.getParamNo().trim());
            if (indexParamsEntity != null) {
                paramNoExactHit = true;
                String parentParamNo = indexParamsEntity.getParentParamNo();
                IndexParamsEntity parentEntity = indexParamsService.getById(parentParamNo);
                if (Objects.isNull(parentEntity)) {
                    queryWrapper.and(qr -> qr.eq(IndexParamsEntity::getParamNo, reqMsg.getParamNo()).or().eq(IndexParamsEntity::getParentParamNo, indexParamsEntity.getParamNo()));
                } else {
                    queryWrapper.and(qr -> qr.eq(IndexParamsEntity::getParamNo, reqMsg.getParamNo()).or().eq(IndexParamsEntity::getParentParamNo, parentParamNo).or().eq(IndexParamsEntity::getParamNo, parentParamNo));
                }
                records = indexParamsService.list(queryWrapper);
            }
        }
        if (!paramNoExactHit) {
            // 模糊兜底：精确命中不到就按 LIKE 检索指标ID本身
            if (StringUtils.isNotEmpty(reqMsg.getParamNo())) {
                queryWrapper.like(IndexParamsEntity::getParamNo, reqMsg.getParamNo().trim());
            }
            // 列表范围 = **挂在可见分组下的指标**（父节点是分组编号，或授权集合里混存的指标编号）。
            // 不加这个条件会把 parentParamNo 不是分组的行（本地 950 条）也当成一级指标列出来 →
            // 总数虚高（1091 vs 线上 136），且分页每页混入父子同行、被 buildTree 折叠后条数不足。
            queryWrapper.in(IndexParamsEntity::getParentParamNo, indexIdList);
            queryWrapper.orderByDesc(IndexParamsEntity::getInputTime);
            Page<IndexParamsEntity> page = new Page<>(reqMsg.getPageIndex(), reqMsg.getPageSize());
            IPage<IndexParamsEntity> pageList = indexParamsService.page(page, queryWrapper);
            if (pageList.getTotal() <= 0) {
                return new ListResult<>(0, 0);
            }
            totalSize = (int) pageList.getTotal();
            records = pageList.getRecords();
            List<String> paramNoList = records.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
            LambdaQueryWrapper<IndexParamsEntity> childWrapper = Wrappers.lambdaQuery();
            childWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamID, IndexParamsEntity::getParamName, IndexParamsEntity::getParamType, IndexParamsEntity::getDataMethod, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getInputMethod, IndexParamsEntity::getInputUserID, IndexParamsEntity::getUpdateUserID, IndexParamsEntity::getInputTime, IndexParamsEntity::getUpdateTime, IndexParamsEntity::getScript, IndexParamsEntity::getScriptType, IndexParamsEntity::getSupplierId, IndexParamsEntity::getIntfNo);
            childWrapper.in(IndexParamsEntity::getParentParamNo, paramNoList);
            List<IndexParamsEntity> childList = indexParamsService.list(childWrapper);
            if (CollectionUtils.isNotEmpty(childList)) {
                records.addAll(childList);
            }
        }
        if (CollectionUtils.isEmpty(records)) {
            return new ListResult<>(0, 0);
        }
        List<IndexParamsEntity> indexParamsEntityList = TreeUtil.buildTree(records, IndexParamsEntity::getParamNo, IndexParamsEntity::getParentParamNo);
        List<IndexParamsDTO> indexParamsDTOList = new ArrayList<>();
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            // 🚀 先按「本页出现过的数据源 id」一次批量取回，避免逐行 getById（原 N+1：10 条/页 = 10 次
            //    selectById(100 条/页 = 100 次)。见 prefetchDataSources 的说明）
            Map<String, SysDataSource> dataSourceMap = prefetchDataSources(indexParamsEntityList);
            indexParamsEntityList.forEach(param -> indexParamsDTOList.add(toIndexParamsDTO(param, dataSourceMap)));
        }
        return new ListResult<>(totalSize, reqMsg.getPageSize(), reqMsg.getPageIndex(), indexParamsDTOList);
    }

    private String getScriptTypeDesc(String scriptType) {
        if (StringUtils.isEmpty(scriptType)) {
            return "";
        }
        ScriptTypeEnum scriptTypeEnum = ScriptTypeEnum.getById(scriptType);
        return Objects.isNull(scriptTypeEnum) ? "" : scriptTypeEnum.name;
    }

    /**
     * 批量预取本页涉及的数据源（修 N+1）
     *
     * <p>背景：列表「数据来源」列由 {@link #getIndexSource} 运行时拼出，其中要拿
     * `script.dataSource` 去换数据源的 code/name。原先**每行一次** `sysDataSourceService.getById(...)`
     * → 10 条/页 = 10 次 selectById，100 条/页 = 100 次（实测 01:07:24 一个请求内连打 10 次，
     * 约 15ms/次）。而 `sys_data_source` 全表通常只有几条，整表拉下来都比逐行取便宜。</p>
     *
     * <p>做法：先扫一遍本页的 `script` 取出出现过的数据源 id，一次 `listByIds` 取回建成 Map，
     * 供 {@link #buildSqlIndexSource} 查。**只覆盖 SQL 类型**（Api/KnowledgeCode 不查数据源）。</p>
     *
     * @return 数据源 id → 实体；本页没有 SQL 类型或都没配数据源时返回空 Map（调用方按"取不到"处理）
     */
    private Map<String, SysDataSource> prefetchDataSources(List<IndexParamsEntity> rows) {
        if (CollectionUtils.isEmpty(rows)) {
            return Collections.emptyMap();
        }
        Set<String> dataSourceIds = new HashSet<>();
        collectDataSourceIds(rows, dataSourceIds);
        if (dataSourceIds.isEmpty()) {
            return Collections.emptyMap();
        }
        try {
            List<SysDataSource> dataSourceList = sysDataSourceService.listByIds(dataSourceIds);
            if (CollectionUtils.isEmpty(dataSourceList)) {
                return Collections.emptyMap();
            }
            Map<String, SysDataSource> map = new HashMap<>(dataSourceList.size());
            for (SysDataSource dataSource : dataSourceList) {
                map.put(dataSource.getId(), dataSource);
            }
            return map;
        } catch (Exception e) {
            // 批量取失败不能影响列表渲染：降级为"数据来源取不到"，与单条取不到时的表现一致
            log.error("批量预取数据源失败，dataSourceIds：{}，异常：{}", dataSourceIds, e.getMessage());
            return Collections.emptyMap();
        }
    }

    /**
     * 实体树 → DTO 树（**递归**，含全部层级的子指标）
     *
     * <p>为什么必须递归（2026-09-16 修）：{@code queryAllList} 返回的是**树**
     * （{@code TreeUtil.buildTree}），前端 antd Table 按默认的 {@code childrenColumnName='children'}
     * 把子指标渲染成**可展开的子行**。原实现只给**顶层根**做了
     * {@code BeanUtil.copyProperties(entity, dto)}，子节点仍是 {@code IndexParamsEntity} 实体 →
     * 子行的「数据源类型 / 数据源配置」两列**恒为空白**（{@code scriptTypeDesc} / {@code indexSource}
     * 是 DTO 独有字段，实体上没有）。</p>
     */
    private IndexParamsDTO toIndexParamsDTO(IndexParamsEntity param, Map<String, SysDataSource> dataSourceMap) {
        IndexParamsDTO dto = new IndexParamsDTO();
        BeanUtil.copyProperties(param, dto, true);
        // copyProperties 会把实体的 children（List<IndexParamsEntity>）按引用带过来 —— 必须清掉再填 DTO 版本，
        // 否则子节点还是实体、字段对不上（这也是本条 bug 的成因）。
        dto.setChildren(null);
        dto.setScriptType(param.getScriptType());
        dto.setScriptTypeDesc(getScriptTypeDesc(param.getScriptType()));
        dto.setIndexSource(getIndexSource(param, dataSourceMap));
        if (CollectionUtils.isNotEmpty(param.getChildren())) {
            List<IndexParamsDTO> children = new ArrayList<>(param.getChildren().size());
            for (IndexParamsEntity child : param.getChildren()) {
                children.add(toIndexParamsDTO(child, dataSourceMap));
            }
            dto.setChildren(children);
        }
        return dto;
    }

    /**
     * 递归收集「树里出现过」的数据源 id（**顶层 + 全部子节点**）
     *
     * <p>只扫顶层会漏掉子指标的数据源 → 子行的 `indexSource` 取不到 code/name（配合
     * {@link #toIndexParamsDTO} 一起修）。</p>
     */
    private void collectDataSourceIds(List<IndexParamsEntity> rows, Set<String> dataSourceIds) {
        if (CollectionUtils.isEmpty(rows)) {
            return;
        }
        for (IndexParamsEntity row : rows) {
            if (ScriptTypeEnum.SQL.id.equals(row.getScriptType())) {
                String id = parseDataSourceId(row.getScript());
                if (StringUtils.isNotEmpty(id)) {
                    dataSourceIds.add(id);
                }
            }
            collectDataSourceIds(row.getChildren(), dataSourceIds);
        }
    }

    /** 从 `script` JSON 里取 `dataSource`（数据源主键）；解析不了返回空串 */
    private String parseDataSourceId(String script) {
        if (StringUtils.isEmpty(script)) {
            return "";
        }
        try {
            return StringUtils.defaultString(JSONObject.parseObject(script).getString("dataSource"));
        } catch (Exception e) {
            return "";
        }
    }

    private String getIndexSource(IndexParamsEntity param, Map<String, SysDataSource> dataSourceMap) {
        String scriptType = param.getScriptType();
        if (StringUtils.isEmpty(scriptType)) {
            return "";
        }
        if (ScriptTypeEnum.API.id.equals(scriptType)) {
            String supplierId = StringUtils.isEmpty(param.getSupplierId()) ? "" : param.getSupplierId();
            String intfNo = StringUtils.isEmpty(param.getIntfNo()) ? "" : param.getIntfNo();
            return "服务编号：" + supplierId + "\n接口编号：" + intfNo;
        }
        if (ScriptTypeEnum.SQL.id.equals(scriptType)) {
            String script = param.getScript();
            if (StringUtils.isEmpty(script)) {
                return "";
            }
            return buildSqlIndexSource(script, dataSourceMap);
        }
        return "";
    }

    private String buildSqlIndexSource(String script, Map<String, SysDataSource> dataSourceMap) {
        try {
            JSONObject scriptJson = JSONObject.parseObject(script);
            String dataSource = scriptJson.getString("dataSource");
            String sql = scriptJson.getString("sql");
            if (StringUtils.isEmpty(dataSource) || StringUtils.isEmpty(sql)) {
                return "";
            }
            // 数据源的code和name：从本页预取好的 Map 里拿（不再逐行查库）
            SysDataSource sysDataSource = dataSourceMap == null ? null : dataSourceMap.get(dataSource);
            String code = Objects.isNull(sysDataSource) ? "" : StringUtils.defaultString(sysDataSource.getCode());
            String name = Objects.isNull(sysDataSource) ? "" : StringUtils.defaultString(sysDataSource.getName());

            // 解析sql中的表名
            Set<String> tableSet = new LinkedHashSet<>();
            Pattern pattern = Pattern.compile("(?i)\\b(from|join)\\s+([a-zA-Z0-9_\\.]+)");
            Matcher matcher = pattern.matcher(sql);
            while (matcher.find()) {
                String table = matcher.group(2);
                if (StringUtils.isNotEmpty(table)) {
                    if (table.contains(".")) {
                        table = table.substring(table.lastIndexOf(".") + 1);
                    }
                    tableSet.add(table);
                }
            }
            String tables = String.join(",", tableSet);
            return "数据库编号：" + code + "\n" +
                   "数据库名称：" + name + "\n" +
                   "涉及查询的表：" + tables;
        } catch (Exception e) {
            log.error("解析Sql指标来源异常，script：{}，异常：{}", script, e.getMessage());
            return "";
        }
    }

    public void getAllParamsByParentParamNo(List<IndexParamsEntity> list, List<IndexParamsEntity> allList) {
        allList.addAll(list);
        // 指标中 只有输入形式为表格和列表才能作为父指标
        Set<String> collect = list.stream().filter(params -> "LIST".equals(params.getParamType()) || "OBJECT".equals(params.getParamType())).map(IndexParamsEntity::getParamNo).collect(Collectors.toSet());
        if (CollectionUtils.isNotEmpty(collect)) {
            QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
            queryWrapper.in("parentparamno", collect);
            List<IndexParamsEntity> indexParamsEntityList = indexParamsService.list(queryWrapper);
            getAllParamsByParentParamNo(indexParamsEntityList, allList);
        }
    }

    @Override
    public AgentResult<?> insertIndexParamsInfo(IndexParamsInfoSaveReq reqMsg) {
        IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
        BeanUtil.copyProperties(reqMsg, indexParamsEntity, true);
        indexParamsEntity.setInputTime(DateUtil.now());
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        indexParamsEntity.setInputUserID(apiContextModel.getUserName());
        indexParamsEntity.setUpdateTime(DateUtil.now());
        indexParamsEntity.setUpdateUserID(apiContextModel.getUserName());
        indexParamsEntity.setOtherNo(reqMsg.getParentParamNo());
        indexParamsService.save(indexParamsEntity);
        // 处理api指标
        executor.execute(() -> handleApiIntfField(reqMsg.getScriptType(), indexParamsEntity, reqMsg.getIntfField(), indexParamsEntity.getScriptType(), apiContextModel.getUserName()));
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> insertIndexParamsObject(IndexParamsInfoSaveReq reqMsg) {
        IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
        reqMsg.setParamID(UUIDGenerator.generate());
        reqMsg.setReportVersion(StringUtils.isEmpty(reqMsg.getReportVersion()) ? "Public" : reqMsg.getReportVersion());
        reqMsg.setParamType(ParamGroupEnum.Group.id);
        BeanUtil.copyProperties(reqMsg, indexParamsEntity, true);
        indexParamsEntity.setInputTime(DateUtil.now());
        indexParamsService.save(indexParamsEntity);
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> deleteIndexParamsList(String paramNo) {
        boolean delete = indexParamsService.removeById(paramNo);
        if (delete) {
            List<IndexParamsEntity> list = indexParamsService.selectByParentParamNo(paramNo);
            if (list != null) {
                for (IndexParamsEntity indexParams : list) {
                    deleteIndexParamsList(indexParams.getParamNo());
                }
            }
        }
        return AgentResult.OK();
    }

    @Override
    public AgentResult<?> queryIndexParamsInfo(IndexParamsInfoReq reqMsg) {
        return AgentResult.OK(indexParamsService.getById(reqMsg.getParamNo()));
    }

    @Override
    public AgentResult<?> updateIndexParamsInfo(IndexParamsInfoSaveReq reqMsg) {
        IndexParamsEntity paramsEntity = indexParamsService.getById(reqMsg.getParamNo());
        if (Objects.isNull(paramsEntity)) {
            return AgentResult.error("更新失败！");
        }

        IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
        BeanUtil.copyProperties(reqMsg, indexParamsEntity, true);
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        indexParamsEntity.setUpdateTime(DateUtil.now());
        indexParamsEntity.setUpdateUserID(apiContextModel.getUserName());
        // 如果未选父级指标，就查当前指标的父级指标
        if (StringUtils.isEmpty(indexParamsEntity.getParentParamNo())) {
            String groupNo = getGroupNo(indexParamsEntity.getParamNo());
            indexParamsEntity.setParentParamNo(groupNo);
            indexParamsEntity.setOtherNo(groupNo);
        }
        // 存储父级指标
        indexParamsService.updateById(indexParamsEntity);
        // 处理api指标
        executor.execute(() -> handleApiIntfField(reqMsg.getScriptType(), indexParamsEntity, reqMsg.getIntfField(), paramsEntity.getScriptType(), apiContextModel.getUserName()));
        return AgentResult.OK();
    }

    private void handleRelateIndex(IndexParamsEntity indexParamsEntity, String originalScriptType) {
        // 查询所有子指标
        List<String> paramNoList = new ArrayList<>();
        List<IndexParamsEntity> parentParamList = indexParamsService.selectByParentParamNo(indexParamsEntity.getParamNo());
        if (CollectionUtils.isNotEmpty(parentParamList)) {
            paramNoList = parentParamList.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
        }
        String paramNo = indexParamsEntity.getParamNo();
        paramNoList.add(paramNo);

        Set<String> newSet = new HashSet<>();
        String scriptType = indexParamsEntity.getScriptType();
        String intfParams = indexParamsEntity.getIntfParams();
        if (StringUtils.isNotEmpty(intfParams) && "Api".equalsIgnoreCase(scriptType)) {
            JSONArray jsonArray = JSONArray.parseArray(intfParams);
            jsonArray.forEach(json -> {
                JSONObject object = (JSONObject) json;
                object.keySet().forEach(key -> {
                    JSONObject value = object.getJSONObject(key);
                    if (Objects.nonNull(value)) {
                        JSONObject relateIndex = value.getJSONObject("relateIndex");
                        if (Objects.nonNull(relateIndex) && StringUtils.isNotEmpty(relateIndex.getString("no"))) {
                            newSet.add(relateIndex.getString("no"));
                        }
                    }
                });
            });
        }
        String script = indexParamsEntity.getScript();
        if (StringUtils.isNotEmpty(script) && "Sql".equalsIgnoreCase(scriptType)) {
            JSONObject jsonObject = JSONObject.parseObject(script);
            JSONArray jsonArray = jsonObject.getJSONArray("paramData");
            if (CollectionUtils.isNotEmpty(jsonArray)) {
                jsonArray.forEach(json -> {
                    JSONObject object = (JSONObject) json;
                    if (Objects.nonNull(object)) {
                        JSONObject relateIndex = object.getJSONObject("relateIndex");
                        if (Objects.nonNull(relateIndex)) {
                            newSet.add(relateIndex.getString("no"));
                        }
                    }
                });
            }
        }

        if (!scriptType.equals(originalScriptType)) {
            indexRelateInfoService.removeRelateInfoByIndexId(paramNoList);
        }

        if (CollectionUtils.isEmpty(newSet)) {
            return;
        }

        List<String> newList = new ArrayList<>(newSet);
        List<String> relateIndexList = indexRelateInfoService.getRelateIndexList(paramNoList);
        if (CollectionUtils.isEmpty(relateIndexList)) {
            indexRelateInfoService.saveRelateInfo(paramNoList, newList);
            return;
        }
        List<String> deleteList = relateIndexList.stream().filter(item -> !newList.contains(item)).collect(Collectors.toList());
        List<String> addList = newList.stream().filter(item -> !relateIndexList.contains(item)).collect(Collectors.toList());
        if (CollectionUtils.isNotEmpty(deleteList)) {
            indexRelateInfoService.removeRelateInfo(paramNoList, deleteList);
        }
        if (CollectionUtils.isNotEmpty(addList)) {
            indexRelateInfoService.saveRelateInfo(paramNoList, addList);
        }
    }

    private void handleApiIntfField(String scriptType, IndexParamsEntity parentIndexParamEntity, String intfField, String parentScriptType, String userName) {
        if (ScriptTypeEnum.API.id.equalsIgnoreCase(scriptType)) {
            List<IndexParamsEntity> indexParamsEntityList = new ArrayList<>();
            List<String> fieldList = JSONArray.parseArray(intfField, String.class);

            for (String field : fieldList) {
                try {
                    IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
                    indexParamsEntity.setModelNo("Public");
                    indexParamsEntity.setDataMethod("Auto");
                    indexParamsEntity.setReportVersion("Public");
                    indexParamsEntity.setInputMethod("label");
                    indexParamsEntity.setScriptType("Api");
                    indexParamsEntity.setIntfField(field);
                    indexParamsEntity.setInputTime(DateUtil.now());
                    indexParamsEntity.setUpdateTime(DateUtil.now());
                    indexParamsEntity.setParentParamNo(parentIndexParamEntity.getParamNo());
                    indexParamsEntity.setParentParamName(parentIndexParamEntity.getParamName());

                    String extendKey = "";
                    String[] split = field.split("@@");
                    for (String s : split) {
                        JSONObject jsonObject = JSONObject.parseObject(s);
                        for (String key : jsonObject.keySet()) {
                            if (StringUtils.isEmpty(extendKey)) {
                                extendKey = key;
                            } else {
                                extendKey = extendKey + "@@" + key;
                            }
                            break;
                        }
                    }
                    indexParamsEntity.setStructure(extendKey);

                    JSONObject object = JSONObject.parseObject(split[split.length - 1]);
                    String paramId = "";
                    JSONObject paramInfo = new JSONObject();
                    for (String key : object.keySet()) {
                        paramId = key;
                        paramInfo = object.getJSONObject(key);
                        break;
                    }
                    indexParamsEntity.setParamID(paramId);
                    indexParamsEntity.setParamName(paramInfo.getString("name"));
                    String transParamType = transParamType(paramInfo.getString("type"));
                    indexParamsEntity.setParamType(transParamType);
                    indexParamsEntityList.add(indexParamsEntity);
                    // 如果为列表类型，新增一条统计数量指标
                    if (ParamTypeEnum.LIST.id.equals(transParamType)) {
                        IndexParamsEntity indexParamsEntityCount = new IndexParamsEntity();
                        indexParamsEntityCount.setModelNo("Public");
                        indexParamsEntityCount.setDataMethod("Auto");
                        indexParamsEntityCount.setReportVersion("Public");
                        indexParamsEntityCount.setInputMethod("label");
                        indexParamsEntityCount.setScriptType("Api");
                        indexParamsEntityCount.setIntfField(field + "@@count");
                        indexParamsEntityCount.setParentParamNo(parentIndexParamEntity.getParamNo());
                        indexParamsEntityCount.setParentParamName(parentIndexParamEntity.getParamName());
                        indexParamsEntityCount.setParamID(paramId + "_count");
                        indexParamsEntityCount.setParamName(paramId + "_count");
                        indexParamsEntityCount.setParamType(ParamTypeEnum.NUMBER.id);
                        indexParamsEntityCount.setInputTime(DateUtil.now());
                        indexParamsEntityCount.setUpdateTime(DateUtil.now());
                        indexParamsEntityList.add(indexParamsEntityCount);
                    }
                } catch (Exception e) {
                    log.error("{}字段处理异常！", field);
                }
            }

            LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
            queryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getIntfField, IndexParamsEntity::getParamID, IndexParamsEntity::getStructure);
            queryWrapper.in(IndexParamsEntity::getParentParamNo, parentIndexParamEntity.getParamNo());
            List<IndexParamsEntity> existIndexParamEntityList = indexParamsService.list(queryWrapper);
            List<IndexParamsEntity> deleteIndexParamEntityList = new ArrayList<>();
            List<IndexParamsEntity> newIndexParamsEntityList;
            if (CollectionUtils.isNotEmpty(existIndexParamEntityList)) {
                List<String> collect = indexParamsEntityList.stream().map(IndexParamsEntity::getStructure).collect(Collectors.toList());
                List<String> existCollect = existIndexParamEntityList.stream().map(IndexParamsEntity::getStructure).collect(Collectors.toList());
                deleteIndexParamEntityList = existIndexParamEntityList.stream().filter(index -> !collect.contains(index.getStructure())).collect(Collectors.toList());
                newIndexParamsEntityList = indexParamsEntityList.stream().filter(index -> !existCollect.contains(index.getStructure())).collect(Collectors.toList());
            } else {
                newIndexParamsEntityList = indexParamsEntityList;
            }
            if (CollectionUtils.isNotEmpty(deleteIndexParamEntityList)) {
                List<String> paramNoList = deleteIndexParamEntityList.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
                indexParamsService.removeByIds(paramNoList);
            }
            if (CollectionUtils.isNotEmpty(newIndexParamsEntityList)) {
                newIndexParamsEntityList.forEach(index -> {
                    index.setUpdateUserID(userName);
                    index.setInputUserID(userName);
                });
                indexParamsService.saveBatch(newIndexParamsEntityList);
                // 更新父级指标层级关系otherNo
                List<IndexParamsEntity> allIndexParamsEntityList = new ArrayList<>();
                allIndexParamsEntityList.addAll(existIndexParamEntityList);
                allIndexParamsEntityList.addAll(newIndexParamsEntityList);
                Map<String, List<IndexParamsEntity>> structMap = allIndexParamsEntityList.stream().filter(index -> StringUtils.isNotEmpty(index.getStructure())).collect(Collectors.groupingBy(IndexParamsEntity::getStructure));
                for (IndexParamsEntity entity : newIndexParamsEntityList) {
                    if (StringUtils.isNotEmpty(entity.getStructure())) {
                        String structure = entity.getStructure();
                        if (!structure.contains("@@")) {
                            entity.setOtherNo(entity.getParamNo());
                            continue;
                        }
                        String trimStructure = entity.getStructure().replace("@@" + entity.getParamID(), "");
                        List<IndexParamsEntity> parentIndexParams = structMap.get(trimStructure);
                        if (CollectionUtils.isNotEmpty(parentIndexParams)) {
                            entity.setOtherNo(parentIndexParams.get(0).getParamNo());
                        }
                    }
                }
                indexParamsService.updateBatchById(newIndexParamsEntityList);
            }
        }
        // 处理父级指标的关联指标
        handleRelateIndex(parentIndexParamEntity, parentScriptType);
    }

    private String transParamType(String paramType) {
        String type = "";
        if (DataTypeEnum.OBJECT.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.OBJECT.id;
        }
        if (DataTypeEnum.ARRAY.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.LIST.id;
        }
        if (DataTypeEnum.STRING.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.CHAR.id;
        }
        if (DataTypeEnum.NUMBER.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.NUMBER.id;
        }
        if (DataTypeEnum.DATE.getValue().equalsIgnoreCase(paramType)) {
            return ParamTypeEnum.DATE.id;
        }
        return type;
    }

    public String getGroupNo(String paramNo) {
        IndexParamsEntity paramsEntity = indexParamsService.getById(paramNo);
        if (Objects.isNull(paramsEntity)) {
            return "";
        }
        if (paramsEntity.getParamType().equals(ParamGroupEnum.Group.id)) {
            return paramsEntity.getParamNo();
        }
        return getGroupNo(paramsEntity.getParentParamNo());
    }

    @Override
    public AgentResult<?> updateIndexParamsObject(IndexParamsInfoSaveReq reqMsg) {
        LambdaUpdateWrapper<IndexParamsEntity> updateWrapper = Wrappers.lambdaUpdate();
        updateWrapper.set(IndexParamsEntity::getParamName, reqMsg.getParamName());
        updateWrapper.eq(IndexParamsEntity::getParamNo, reqMsg.getParamNo());
        indexParamsService.update(updateWrapper);
        return AgentResult.OK();
    }

    @Async
    @Override
    public void refreshIndexCache() {
        String cacheKey = MD5.create().digestHex("demo_call_all_index_param_cache", StandardCharsets.UTF_8);
        doubleCache.remove(cacheKey);
        List<IndexParamsSimpleDTO> listResult = queryAllIndexParamsList(new IndexParamQueryReq());
        doubleCache.set(cacheKey, JSONObject.toJSONString(listResult), 60 * 60 * 2);
    }

    @Override
    public List<IndexParamsSimpleDTO> queryAllIndexParamsList(IndexParamQueryReq reqMsg) {
        List<IndexParamsSimpleDTO> indexParamsDTOList = new ArrayList<>();
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.select(IndexParamsEntity::getParamNo, IndexParamsEntity::getParamName, IndexParamsEntity::getInputMethod, IndexParamsEntity::getScriptType, IndexParamsEntity::getParamType, IndexParamsEntity::getParentParamNo, IndexParamsEntity::getParentParamName);
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParentParamNo()), IndexParamsEntity::getParentParamNo, reqMsg.getParentParamNo());
        queryWrapper.eq(IndexParamsEntity::getModelNo, "Public");
        queryWrapper.ne(IndexParamsEntity::getParamType, "GROUP");
        List<IndexParamsEntity> paramsList = indexParamsService.list(queryWrapper);
        if (CollectionUtils.isEmpty(paramsList)) {
            return indexParamsDTOList;
        }

        LambdaQueryWrapper<IndexBaseGroupEntity> groupQueryWrapper = Wrappers.lambdaQuery();
        groupQueryWrapper.select(IndexBaseGroupEntity::getGroupId, IndexBaseGroupEntity::getGroupName, IndexBaseGroupEntity::getParentGroupId, IndexBaseGroupEntity::getParentGroupName);
        List<IndexBaseGroupEntity> groupList = indexBaseGroupService.list(groupQueryWrapper);
        if (CollectionUtils.isEmpty(groupList)) {
            return indexParamsDTOList;
        }
        groupList.forEach(group -> {
            IndexParamsEntity indexParamsEntity = new IndexParamsEntity();
            indexParamsEntity.setParamNo(group.getGroupId());
            indexParamsEntity.setParamName(group.getGroupName());
            indexParamsEntity.setParentParamNo(group.getParentGroupId());
            indexParamsEntity.setParentParamName(group.getParentGroupName());
            paramsList.add(indexParamsEntity);
        });

        List<IndexParamsEntity> indexParamsEntityList = TreeUtil.buildTree(paramsList, IndexParamsEntity::getParamNo, IndexParamsEntity::getParentParamNo);
        if (CollectionUtils.isNotEmpty(paramsList)) {
            indexParamsEntityList.forEach(param -> {
                IndexParamsSimpleDTO indexParamsDTO = new IndexParamsSimpleDTO();
                BeanUtil.copyProperties(param, indexParamsDTO, true);
                indexParamsDTOList.add(indexParamsDTO);
            });
        }
        return indexParamsDTOList;
    }

    @Override
    public ListResult<?> queryIndexParamsListFromCache(IndexParamQueryReq reqMsg) {
        String cacheKey = MD5.create().digestHex("demo_call_all_index_param_cache", StandardCharsets.UTF_8);
        String cacheValue = doubleCache.getValue(cacheKey);
        if (StringUtils.isNotEmpty(cacheValue)) {
            return new ListResult<>(JSONObject.parseArray(cacheValue, IndexParamsSimpleDTO.class));
        }
        List<IndexParamsSimpleDTO> listResult = queryAllIndexParamsList(reqMsg);
        doubleCache.set(cacheKey, JSONObject.toJSONString(listResult), 60 * 60 * 2);
        return new ListResult<>(listResult);
    }

    @Override
    public boolean addIndexGroup(IndexBaseGroupVO indexBaseGroupVO) {
        IndexBaseGroupEntity indexBaseGroupEntity = new IndexBaseGroupEntity();
        BeanUtil.copyProperties(indexBaseGroupVO, indexBaseGroupEntity, true);
        indexBaseGroupEntity.setInputTime(DateUtil.now());
        indexBaseGroupEntity.setUpdateTime(DateUtil.now());
        return indexBaseGroupService.save(indexBaseGroupEntity);
    }

    @Override
    public ListResult<?> queryIndexBaseGroupTree(String groupName, String groupValue) {
        // 权限过滤：indexIdList = 可见分组编号集合（空 = 无授权 → fail-closed），口径详见 getIndexIdListByRoleId()
        List<String> indexIdList = getIndexIdListByRoleId();
        if (CollectionUtils.isEmpty(indexIdList)) {
            return new ListResult<>(0, 0);
        }

        LambdaQueryWrapper<IndexBaseGroupEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(IndexBaseGroupEntity::getGroupStatus, "1");
        queryWrapper.like(StringUtils.isNotEmpty(groupName), IndexBaseGroupEntity::getGroupName, groupName);
        queryWrapper.like(StringUtils.isNotEmpty(groupValue), IndexBaseGroupEntity::getGroupValue, groupValue);
        queryWrapper.in(CollectionUtils.isNotEmpty(indexIdList), IndexBaseGroupEntity::getGroupId, indexIdList);
        List<IndexBaseGroupEntity> indexBaseGroupEntityList = indexBaseGroupService.list(queryWrapper);
        if (CollectionUtils.isEmpty(indexBaseGroupEntityList)) {
            return new ListResult<>(0, 0);
        }
        List<IndexBaseGroupEntity> IndexBaseGroupTree = TreeUtil.buildTree(indexBaseGroupEntityList, IndexBaseGroupEntity::getGroupId, IndexBaseGroupEntity::getParentGroupId);
        List<IndexBaseGroupDTO> indexBaseGroupDTOList = new ArrayList<>();
        IndexBaseGroupTree.forEach(know -> {
            IndexBaseGroupDTO indexBaseGroupDTO = new IndexBaseGroupDTO();
            BeanUtil.copyProperties(know, indexBaseGroupDTO, true);
            indexBaseGroupDTOList.add(indexBaseGroupDTO);
        });
        return new ListResult<>(indexBaseGroupDTOList);
    }

    @Override
    public boolean updateIndexBaseGroupInfo(IndexBaseGroupVO reqMsg) {
        IndexBaseGroupEntity indexBaseGroupEntity = new IndexBaseGroupEntity();
        BeanUtil.copyProperties(reqMsg, indexBaseGroupEntity, true);
        indexBaseGroupEntity.setUpdateTime(DateUtil.now());
        return indexBaseGroupService.updateById(indexBaseGroupEntity);
    }

    @Override
    public boolean deleteIndexBaseGroupInfo(String groupId) {
        indexBaseGroupService.removeById(groupId);
        // 异步删除其下所有子分组以及分组下所有子指标
        executor.execute(() -> {
            List<String> childGroupIdList = indexBaseGroupService.getAllChildGroupIdList(groupId);
            if (CollectionUtils.isNotEmpty(childGroupIdList)) {
                childGroupIdList.add(groupId);
            } else {
                childGroupIdList = Collections.singletonList(groupId);
            }
            indexBaseGroupService.removeByIds(childGroupIdList);
            indexParamsService.removeAllChildParams(childGroupIdList);
        });
        return true;
    }

    @Override
    public ListResult<?> queryIndexBaseParamsList(IndexBaseGroupReq reqMsg) {
        if (StringUtils.isEmpty(reqMsg.getGroupId())) {
            return new ListResult<>(0, 0);
        }
        QueryWrapper<IndexParamsEntity> queryWrapper = new QueryWrapper<>();
        queryWrapper.eq("parentParamNo", reqMsg.getGroupId());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamId()), "paramid", reqMsg.getParamId());
        queryWrapper.eq(StringUtils.isNotEmpty(reqMsg.getParamName()), "paramname", reqMsg.getParamName());
        queryWrapper.orderByDesc("inputTime");
        List<IndexParamsEntity> paramsList = indexParamsService.list(queryWrapper);
        List<IndexParamsEntity> oneAllParams = new ArrayList<>();
        getAllParamsByParentParamNo(paramsList, oneAllParams);
        List<IndexParamsEntity> indexParamsEntityList = TreeUtil.buildTree(oneAllParams, IndexParamsEntity::getParamNo, IndexParamsEntity::getParentParamNo);
        List<IndexParamsDTO> indexParamsDTOList = new ArrayList<>();
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            indexParamsEntityList.forEach(param -> {
                IndexParamsDTO indexParamsDTO = new IndexParamsDTO();
                BeanUtil.copyProperties(param, indexParamsDTO, true);
                indexParamsDTOList.add(indexParamsDTO);
            });
        }
        return new ListResult<>(indexParamsDTOList);
    }

    @Override
    public AgentResult<?> copyIndexParamsInfo(IndexParamsInfoSaveReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getParamNo()) || StringUtils.isEmpty(reqMsg.getParentParamNo())) {
            return AgentResult.error("参数异常！");
        }

        IndexParamsEntity paramsEntity = indexParamsService.getById(reqMsg.getParamNo());
        if (Objects.isNull(paramsEntity) || (!ParamTypeEnum.LIST.id.equals(paramsEntity.getParamType()) && !ParamTypeEnum.OBJECT.id.equals(paramsEntity.getParamType()))) {
            return AgentResult.error("选择待复制的指标类型异常！！");
        }

        // 生成父级指标
        IndexParamsEntity newParamEntity = new IndexParamsEntity();
        BeanUtil.copyProperties(paramsEntity, newParamEntity, true);
        newParamEntity.setParamNo(null);
        newParamEntity.setParentParamNo(reqMsg.getParentParamNo());
        newParamEntity.setParamID(paramsEntity.getParamID() + "_copy");
        newParamEntity.setParamName(paramsEntity.getParamName() + "_copy");
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        newParamEntity.setInputUserID(apiContextModel.getUserName());
        newParamEntity.setUpdateUserID(apiContextModel.getUserName());
        newParamEntity.setInputTime(DateUtil.now());
        newParamEntity.setUpdateTime(DateUtil.now());
        indexParamsService.save(newParamEntity);

        // 生成子级指标
        String paramNo = paramsEntity.getParamNo();
        LambdaQueryWrapper<IndexParamsEntity> queryWrapper = Wrappers.lambdaQuery();
        queryWrapper.eq(IndexParamsEntity::getParentParamNo, paramNo);
        List<IndexParamsEntity> childIndexParam = indexParamsService.list(queryWrapper);
        if (CollectionUtils.isEmpty(childIndexParam)) {
            return AgentResult.OK(true);
        }
        childIndexParam.forEach(child -> {
            child.setParamNo(null);
            child.setParentParamNo(newParamEntity.getParamNo());
            child.setInputTime(DateUtil.now());
            child.setUpdateTime(DateUtil.now());
            child.setInputUserID(apiContextModel.getUserName());
            child.setUpdateUserID(apiContextModel.getUserName());
        });

        indexParamsService.saveBatch(childIndexParam);

        // 处理otherNo
        Map<String, List<IndexParamsEntity>> structMap = childIndexParam.stream().filter(index -> StringUtils.isNotEmpty(index.getStructure())).collect(Collectors.groupingBy(IndexParamsEntity::getStructure));
        childIndexParam.forEach(child -> {
            if (StringUtils.isNotEmpty(child.getStructure())) {
                String structure = child.getStructure();
                if (!structure.contains("@@")) {
                    child.setOtherNo(child.getParamNo());
                } else {
                    String trimStructure = child.getStructure().replace("@@" + child.getParamID(), "");
                    List<IndexParamsEntity> parentIndexParams = structMap.get(trimStructure);
                    if (CollectionUtils.isNotEmpty(parentIndexParams)) {
                        child.setOtherNo(parentIndexParams.get(0).getParamNo());
                    }
                }
            }
        });
        indexParamsService.updateBatchById(childIndexParam);
        return AgentResult.OK(true);
    }

    @Override
    public AgentResult<?> moveIndexParamsInfo(IndexMoveReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getGroupId()) || StringUtils.isEmpty(reqMsg.getSelectParamNo())) {
            return AgentResult.error("请求参数异常，移动失败！");
        }

        IndexParamsEntity indexParamsEntity = indexParamsService.getById(reqMsg.getSelectParamNo());
        if (Objects.isNull(indexParamsEntity)) {
            return AgentResult.error("移动失败，选择的指标不存在！");
        }

        String groupId = reqMsg.getGroupId();
        IndexBaseGroupEntity indexBaseGroupEntity = indexBaseGroupService.getById(groupId);
        if (Objects.isNull(indexBaseGroupEntity)) {
            return AgentResult.error("移动失败，选择的指标分组不存在！");
        }

        // 向上追溯到顶级父指标（其上一级为分组）
        IndexParamsEntity topParentParam = findTopParentParam(indexParamsEntity);
        if (Objects.isNull(topParentParam)) {
            return AgentResult.error("移动失败，选择的指标不存在！");
        }

        // 仅更新顶级父指标的父分组，子指标的父子关系保持不变
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        topParentParam.setParentParamNo(groupId);
        topParentParam.setParentParamName(indexBaseGroupEntity.getGroupName());
        topParentParam.setUpdateTime(DateUtil.now());
        topParentParam.setUpdateUserID(apiContextModel.getUserName());
        indexParamsService.updateById(topParentParam);
        return AgentResult.OK(true);
    }

    private IndexParamsEntity findTopParentParam(IndexParamsEntity paramEntity) {
        if (Objects.isNull(paramEntity)) {
            return null;
        }
        String parentParamNo = paramEntity.getParentParamNo();
        if (StringUtils.isEmpty(parentParamNo)) {
            return paramEntity;
        }
        IndexParamsEntity parentEntity = indexParamsService.getById(parentParamNo);
        // 父级不存在或父级为分组类型，说明当前指标即为顶级指标
        if (Objects.isNull(parentEntity) || ParamGroupEnum.Group.id.equals(parentEntity.getParamType())) {
            return paramEntity;
        }
        return findTopParentParam(parentEntity);
    }

    @Override
    public AgentResult<?> getRelateParamsList(IndexParamsInfoReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getParamNo())) {
            return AgentResult.error("参数异常！");
        }
        String paramNo = reqMsg.getParamNo();
        IndexParamsEntity paramsEntity = indexParamsService.getById(paramNo);
        if (Objects.isNull(paramsEntity)) {
            return AgentResult.error("未查询到相关数据！");
        }
        IndexParamsEntity parentParamEntity = indexParamsService.getById(paramsEntity.getParentParamNo());
        if (Objects.isNull(parentParamEntity)) {
            return AgentResult.error("未查询到相关数据！");
        }

        JSONArray resultArray = new JSONArray();
        List<IndexParamsEntity> childIndexParamList = indexParamsService.selectByOtherNo(paramNo, paramsEntity.getScriptType());
        if (CollectionUtils.isNotEmpty(childIndexParamList)) {
            Map<String, String> realParamNameMap = getRealParamName(childIndexParamList, parentParamEntity.getExtendField());
            childIndexParamList.forEach(child -> {
                JSONObject jsonObject = new JSONObject();
                String mapName = realParamNameMap.get(child.getParamNo());
                jsonObject.put("label", StringUtils.isEmpty(mapName) ? child.getParamName() : mapName);
                jsonObject.put("value", StringUtils.isEmpty(mapName) ? child.getParamName() : mapName);
                jsonObject.put("paramNo", child.getParamNo());
                resultArray.add(jsonObject);
            });

        }
        return AgentResult.OK(resultArray);
    }

    private Map<String, String> getRealParamName(List<IndexParamsEntity> childIndexParamList, String extendField) {
        Map<String, String> resultMap = new HashMap<>();
        try {
            childIndexParamList.forEach(child -> {
                String structure = child.getStructure();
                JSONArray extentFieldArray = JSONArray.parseArray(extendField);
                for (Object obj : extentFieldArray) {
                    JSONObject jsonObject = (JSONObject) obj;
                    if (jsonObject.containsKey(structure)) {
                        JSONObject json = jsonObject.getJSONObject(structure);
                        resultMap.put(child.getParamNo(), json.isEmpty() ? child.getParamName() : json.getString("relaPname"));
                        break;
                    }
                }
            });
        } catch (Exception e) {
            log.error("获取指标参数真实名称失败，参数：{}，异常：{}", extendField, e.getMessage());
        }
        return resultMap;
    }

    @Override
    public AgentResult<?> queryRelateKnowledgeInfo(IndexParamsInfoReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getParamNo())) {
            throw new AgentBizException("参数异常！");
        }
        String paramNo = reqMsg.getParamNo();
        IndexParamsEntity paramsEntity = indexParamsService.getById(paramNo);
        if (Objects.isNull(paramsEntity)) {
            throw new AgentBizException("未查询到相关数据！");
        }
        List<String> paramNoList = Collections.emptyList();
        List<IndexParamsEntity> indexParamsEntityList = indexParamsService.selectByParentParamNo(paramNo);
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            paramNoList = indexParamsEntityList.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
        }
        // 查询关联知识库信息
        return AgentResult.OK(indexRelateKnowledgeInfoService.getListByParamNo(reqMsg, paramNoList));
    }

    @Override
    public AgentResult<?> queryRelateIndexInfo(IndexParamsInfoReq reqMsg) {
        if (Objects.isNull(reqMsg) || StringUtils.isEmpty(reqMsg.getParamNo())) {
            throw new AgentBizException("参数异常！");
        }
        String paramNo = reqMsg.getParamNo();
        IndexParamsEntity paramsEntity = indexParamsService.getById(paramNo);
        if (Objects.isNull(paramsEntity)) {
            throw new AgentBizException("未查询到相关数据！");
        }
        List<String> paramNoList = Collections.emptyList();
        List<IndexParamsEntity> indexParamsEntityList = indexParamsService.selectByParentParamNo(paramNo);
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            paramNoList = indexParamsEntityList.stream().map(IndexParamsEntity::getParamNo).collect(Collectors.toList());
        }
        return AgentResult.OK(indexRelateIndexInfoService.getListByParamNo(reqMsg, paramNoList));
    }

    @Override
    public AgentResult<?> queryIndexRelateKnowledgeInfo(String paramNo) {
        return AgentResult.OK(knowledgeBaseParamsService.generateIndexRelateKnowledgeInfo(paramNo));
    }

    /**
     * 解析当前调用者可访问的「指标分组」范围 —— 左侧分组树与右侧指标列表共用同一份口径
     *
     * <p><b>返回值只有两种语义（2026-09-15 由"三态"收敛为两态）：</b></p>
     * <table border="1">
     *   <tr><th>返回值</th><th>含义</th><th>调用方应做</th></tr>
     *   <tr><td>非空</td><td><b>可见的分组编号集合</b></td>
     *       <td>加 in 条件：树按 {@code index_base_group.groupId}，
     *           列表按 {@code index_params.parentParamNo}
     *           —— <b>只有挂在分组下的指标才属于列表范围</b></td></tr>
     *   <tr><td>空列表</td><td>已启用过滤，但该角色<b>一个分组都没授权</b></td>
     *       <td>直接返回空结果（fail-closed："没配授权"不是故障）</td></tr>
     * </table>
     *
     * <p><b>🔴 为什么"放行"不再返回 null（改为返回"全部启用中的分组"）</b>，三个理由：</p>
     * <ol>
     *   <li><b>口径</b>：放行的语义是"被授权了全部分组"（初始化按全量灌 {@code sys_role_index}，<b>不是</b>不过滤），
     *       不是"完全不按分组过滤"。返回 null 会把 {@code index_params} 里 950 条
     *       <b>父节点不是分组</b>的行也当成一级指标列出来 —— 线上是 <b>136 条</b>，本工程却显示 1091 条。</li>
     *   <li><b>踩过的坑</b>：null 到了旧调用方，`CollectionUtils.isEmpty(null) == true` 会被误判成
     *       "无授权" → 右侧列表直接空白（2026-09-15 自测实测）。</li>
     *   <li><b>分页错乱</b>：不过滤时，一页 10 条里会混进"父子同页"的行，被 {@code TreeUtil.buildTree}
     *       折叠进 children 后就不是 10 条了（实测第 2 页只剩 2 条）。</li>
     * </ol>
     *
     * <p><b>关于 {@code sys_role_index.index_id} 存的是什么</b>：它<b>混合存两类 id</b>——
     * 指标编号（{@code index_params.paramno}）与分组编号（{@code index_base_group.groupid}）。
     * 列表按 {@code parentParamNo}、树按 {@code groupId} 过滤，所以指标编号那部分在树里用不上，
     * 但**不要**过滤掉（源工程同样混存，且列表的 in 条件需要它兜住"父节点是指标"的层级）。</p>
     */
    private List<String> getIndexIdListByRoleId() {
        // ① 开关关闭：不做角色过滤，但范围依旧是「全部分组」（不是"不过滤"）
        if (!agentProperties.isIndexRoleFilterEnabled()) {
            return listAllEnabledGroupIds();
        }
        ApiContextModel apiContextModel = ApiContext.getApiContextModel();
        List<String> roleCodes = apiContextModel.getRoleCode();

        // 🔴 2026-09-22 第二次口径调整：**已删除原「菜单全通角色放行」分支**。
        //    原分支按 `sys_role.menu_permissions` 含裸 "*" 判定（agentRoleMapper#countFullMenuRoles），
        //    但客户最终确定的角色模型里**管理员并不持有 "*"**（管理员默认只看报告管理/智策引擎/系统管理）
        //    ⇒ 该旁路既失效、又会让"数据授权页里配的东西不生效"，故整体移除。
        //    现回归**纯数据表驱动**：指标可见性完全由 sys_role_index 决定，
        //    配合「初始化灌全量 + 数据授权页一键全选」应对新增分组。
        //    ⚠️ 因此 admin 的 sys_role_index 必须有数据，否则指标配置页会空白 —— 见增量 DML。

        // ② sys_role_index.role_id 的口径是「角色主键」（sys_role.id），由 ApiContext 按 userId 查出。
        List<String> roleIdList = apiContextModel.getRoleIdList();
        if (CollectionUtils.isEmpty(roleIdList)) {
            log.warn("启用角色-指标过滤但取不到当前用户的角色主键（userId={}，roleCode={}），本次按「全部分组」放行；"
                            + "请检查 sys_user_role 是否有该用户的关联记录",
                    apiContextModel.getUserId(), roleCodes);
            return listAllEnabledGroupIds();
        }

        List<String> indexIdList = sysRoleIndexService.getIndexIdListByRoleId(roleIdList);
        // 源实现在查不到授权时返回 null，这里归一成空列表（= fail-closed：一个分组都没授权）
        return indexIdList == null ? Collections.<String>emptyList() : indexIdList;
    }

    /**
     * 全部「启用中」的分组编号（{@code groupStatus = '1'}），与左侧分组树取数口径逐字一致。
     *
     * <p>用于「放行」场景（开关关闭 / 超管 / 取不到角色）：<b>超管不是"不过滤"，而是"被授权了全部分组"</b>。</p>
     */
    private List<String> listAllEnabledGroupIds() {
        LambdaQueryWrapper<IndexBaseGroupEntity> wrapper = Wrappers.lambdaQuery();
        wrapper.select(IndexBaseGroupEntity::getGroupId);
        wrapper.eq(IndexBaseGroupEntity::getGroupStatus, "1");
        List<IndexBaseGroupEntity> groupList = indexBaseGroupService.list(wrapper);
        return groupList.stream().map(IndexBaseGroupEntity::getGroupId).collect(Collectors.toList());
    }
}
