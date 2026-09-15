package com.suzhou.bank.agent.client;

import cn.hutool.http.HttpRequest;
import cn.hutool.http.HttpUtil;
import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.parser.Feature;
import com.suzhou.bank.agent.common.AgentBizException;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;

/**
 * 「检查项解析」外部智能体调用客户端（智策引擎 rule:parse 用）
 *
 * <p><b>它做什么</b>：把业务人员写的自然语言阈值，交给一个名为「审查规则解析智能体」的外部智能体，
 * 拿回结构化结果（最终表达式 / 指标确定 / 特殊指标处理），
 * 详见 {@code AgentRuleServiceImpl#parseRule} 的消费逻辑。</p>
 *
 * <p><b>🔴 迁移改造点：源实现的两个问题已修正</b></p>
 * <ol>
 *   <li><b>硬编码凭据</b>：源实现把 Bearer Token 明文写死在类里
 *       （JWT payload 为 {@code accountId=quanxiafuwqianxu, orgName=千寻预研团队, exp=2027-06-22}）——
 *       即该功能跑在<b>厂商云端、用厂商账号</b>。这里改为配置项
 *       {@code agent.agent-search.url} / {@code agent.agent-search.token}，<b>默认空</b>。</li>
 *   <li><b>硬编码地址</b>：源实现写死内网地址 {@code http://172.20.2.2/qianxun_wf/ai/agentSearch/v1}。同样改为配置。</li>
 * </ol>
 *
 * <p><b>未配置时的行为</b>：抛 {@link AgentBizException} 并给出明确的配置提示，
 * 而不是像源实现那样返回空报文让调用方拿到一堆 null（那种失败最难排查）。
 * 前端「检查项解析」按钮会看到清晰的原因。</p>
 *
 * <p><b>P4 阶段的替代方案（已定）</b>：改用本工程自有大模型
 * （{@code LargeModelGatewayClient} + 提示词 v1 + 本地指标映射），
 * 以摆脱对外部智能体的依赖。届时替换本类的 {@code execute} 实现即可，
 * {@code AgentRuleServiceImpl#parseRule} 的解析逻辑无需改动。</p>
 *
 * <p><b>数据出境提示</b>：若沿用厂商智能体，业务规则文本会经过厂商环境。
 * 这在三个菜单里是<b>唯一一个"数据会出银行"的功能</b>，需按行内要求确认。</p>
 */
@Slf4j
@Repository
public class AgentSearchApiClient {

    /** 智能体检索服务地址（默认空 = 未配置） */
    @Value("${agent.agent-search.url:}")
    private String agentSearchUrl;

    /** 调用凭据（Bearer Token，默认空 = 未配置） */
    @Value("${agent.agent-search.token:}")
    private String token;

    /**
     * 是否已配置外部智能体
     *
     * <p>供 {@code AgentRuleServiceImpl#parseRule} 决定走哪条解析路径：
     * 配了就走厂商智能体，没配就走本工程自有大模型（P4 的默认路线）。</p>
     */
    public boolean isConfigured() {
        return StringUtils.isNotBlank(agentSearchUrl);
    }

    /**
     * 提交解析请求
     *
     * @param params 报文（含 {@code input} 自然语言规则文本、{@code agent_id} 等）
     * @return 智能体返回的 JSON
     */
    public JSONObject execute(JSONObject params) {
        if (StringUtils.isBlank(agentSearchUrl)) {
            throw new AgentBizException("「检查项解析」依赖的外部智能体未配置："
                    + "请在配置中提供 agent.agent-search.url（及需要时的 agent.agent-search.token）。"
                    + "说明：源工程把它硬编码在代码里（厂商预研账号），本工程刻意改为配置项，"
                    + "以避免凭据入库、并便于切换为行内网关或自有大模型。");
        }
        log.info("请求检查项解析智能体，地址：{}", agentSearchUrl);
        try {
            HttpRequest request = HttpUtil.createPost(agentSearchUrl)
                    .header("Content-Type", "application/json;charset=utf-8")
                    .header("Accept", "application/json");
            if (StringUtils.isNotBlank(token)) {
                request.header("Authorization", token.startsWith("Bearer ") ? token : ("Bearer " + token));
            }
            request.body(params.toJSONString(), "application/json;charset=utf-8");
            cn.hutool.http.HttpResponse response = request.execute();
            String body = response.body();
            if (response.getStatus() != 200) {
                log.error("检查项解析智能体调用失败，状态码={}，响应={}", response.getStatus(), body);
                throw new AgentBizException("检查项解析服务调用失败，状态码：" + response.getStatus());
            }
            return JSON.parseObject(body, Feature.OrderedField);
        } catch (AgentBizException e) {
            throw e;
        } catch (Exception e) {
            log.error("检查项解析智能体调用异常", e);
            throw new AgentBizException("检查项解析服务调用异常：" + e.getMessage());
        }
    }
}
