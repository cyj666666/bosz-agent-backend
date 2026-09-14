package com.suzhou.bank.agent.core;

import java.util.List;
import java.util.Map;

/**
 * 数据集构建策略（指标取数的统一抽象）
 *
 * <p>来源：amar-agent-server 的 {@code org.jeecg.modules.agent.core.DataSetBuilder}，原样平移。</p>
 *
 * <p>不同 {@code scriptType} 的指标由不同实现类负责取数，
 * 通过 Spring Bean 名称（{@link #type()}）匹配，实现"新增取数方式不改调用方"。</p>
 */
public interface DataSetBuilder {

    /** 策略标识，与指标配置里的 scriptType 对应（如 {@code Sql}） */
    String type();

    /** 展示名（如 {@code SQL}） */
    String label();

    /**
     * 生成数据集
     *
     * @param paramNo        指标编号
     * @param script         取数脚本（JSON 串，结构见 {@link SqlScript}）
     * @param parameters     入参（会被本方法就地补充默认值/黑盒参数，调用方需注意）
     * @param relateIndexSet 关联细类参数配置（JSON 数组串，可空）
     * @return 数据行列表；取数失败返回 {@code null}（由上层决定降级策略）
     */
    List<?> build(String paramNo, String script, Map<String, Object> parameters, String relateIndexSet);

    /**
     * 规范化数据集（如把数值转为便于展示的形态）
     */
    List<?> formatData(List<?> data);
}
