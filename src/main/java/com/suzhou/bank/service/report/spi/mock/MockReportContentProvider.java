package com.suzhou.bank.service.report.spi.mock;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.suzhou.bank.service.report.spi.ContentPayload;
import com.suzhou.bank.service.report.spi.ReportContentProvider;
import com.suzhou.bank.service.report.spi.ReportGenerateContext;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import org.springframework.util.StreamUtils;
import org.springframework.util.StringUtils;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * 报告内容提供者 · 模拟实现（演示走通用）
 * <p>用前端报告详情页 demo 的内容模拟"前置加工"产物，使报告生成流程可以完整跑通：
 * 内容取自 classpath:{@value #RESOURCE_PATH}，按内容块编号（blockCode）提供内容与块间跳转目标。</p>
 * <p><b>接入真实加工逻辑时</b>：在配置中设置 {@code report.mock-content.enabled: false}
 * （或直接删除本类），容器会自动回退到 {@code DefaultReportContentProvider}（空内容）。</p>
 * <p>内容中的 {@code ${customerName}} 占位符会被替换为当次报告的客户名称
 * （用于报告头大标题——公司名称）。</p>
 *
 * @author cyj666666
 * @since 1.1.0
 */
@Slf4j
@Component
@ConditionalOnProperty(name = "report.mock-content.enabled", havingValue = "true", matchIfMissing = true)
public class MockReportContentProvider implements ReportContentProvider {

    /** 模拟内容资源路径 */
    private static final String RESOURCE_PATH = "report-demo/demo-content.json";

    /** 客户名称占位符 */
    private static final String CUSTOMER_NAME_TOKEN = "${customerName}";

    /** blockCode → 内容成品（懒加载后只读） */
    private volatile Map<String, String> contentMap;

    /** blockCode → 块间跳转目标锚点（懒加载后只读） */
    private volatile Map<String, String> jumpAnchorMap;

    @Override
    public ContentPayload provide(ReportGenerateContext context) {
        ensureLoaded();
        if (context == null || context.getBlock() == null) {
            return null;
        }
        String blockCode = context.getBlock().getBlockCode();
        String content = contentMap.get(blockCode);
        if (!StringUtils.hasText(content)) {
            // 模拟数据中未配置该块（如章节标题块，交由生成器的标题兜底处理）
            return null;
        }
        String customerName = StringUtils.hasText(context.getCustomerName()) ? context.getCustomerName() : "";
        return new ContentPayload(content.replace(CUSTOMER_NAME_TOKEN, customerName), jumpAnchorMap.get(blockCode));
    }

    /** 首次调用时加载模拟内容，失败则按空内容处理（不影响生成流程） */
    private void ensureLoaded() {
        if (contentMap != null) {
            return;
        }
        synchronized (this) {
            if (contentMap != null) {
                return;
            }
            Map<String, String> contents = new HashMap<>();
            Map<String, String> jumpAnchors = new HashMap<>();
            try (InputStream in = new ClassPathResource(RESOURCE_PATH).getInputStream()) {
                JSONObject root = JSON.parseObject(StreamUtils.copyToString(in, StandardCharsets.UTF_8));
                JSONObject contentNode = root.getJSONObject("content");
                if (contentNode != null) {
                    contentNode.forEach((k, v) -> contents.put(k, v == null ? null : String.valueOf(v)));
                }
                JSONObject jumpNode = root.getJSONObject("jumpAnchor");
                if (jumpNode != null) {
                    jumpNode.forEach((k, v) -> jumpAnchors.put(k, v == null ? null : String.valueOf(v)));
                }
                log.warn("已加载报告模拟内容（演示用）：{} 个内容块、{} 条块间跳转；"
                        + "接入真实加工逻辑时请配置 report.mock-content.enabled=false", contents.size(), jumpAnchors.size());
            } catch (Exception e) {
                log.warn("报告模拟内容加载失败（{}），本次将按空内容处理：{}", RESOURCE_PATH, e.getMessage());
            }
            contentMap = contents;
            jumpAnchorMap = jumpAnchors;
        }
    }
}
