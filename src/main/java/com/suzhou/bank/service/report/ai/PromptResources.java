package com.suzhou.bank.service.report.ai;

import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.ClassPathResource;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

/**
 * 提示词兜底资源加载器
 *
 * <p>提示词的<b>首选来源是表 {@code app_report_prompt}</b>，本类只提供「表里没有 / 表读不到」时的
 * 兜底文本，放在 classpath 的 {@code report-prompt/} 下，按文件名加载并缓存。</p>
 *
 * <p>之所以用资源文件而不是 Java 常量：预警建议的提示词内嵌了两千多字的《预警管理办法》原文，
 * 写成 Java 字符串拼接既难维护又容易出错；纯文本文件可以直接阅读和 diff。</p>
 *
 * <p>⚠️ 修改这里的文本后，记得同步更新 {@code sql/报告详情表设计/报告提示词表_初始化DML.sql}，
 * 否则表与兜底内容会不一致。</p>
 *
 * @author cyj666666
 * @since 1.3.0
 */
@Slf4j
final class PromptResources {

    private static final String DIR = "report-prompt/";
    private static final Map<String, String> CACHE = new HashMap<>();

    private PromptResources() {
    }

    /**
     * 读取兜底提示词文本（带缓存）
     *
     * @param fileName 资源文件名，如 {@code AI_FULL_ANALYSIS.system.txt}
     * @return 文本；读不到时返回空串（调用方会发现内容为空并报错，不会静默用空提示词调模型）
     */
    static String load(String fileName) {
        synchronized (CACHE) {
            String cached = CACHE.get(fileName);
            if (cached != null) {
                return cached;
            }
            String text = read(fileName);
            CACHE.put(fileName, text);
            return text;
        }
    }

    private static String read(String fileName) {
        String path = DIR + fileName;
        try (InputStream in = new ClassPathResource(path).getInputStream()) {
            ByteArrayOutputStream bos = new ByteArrayOutputStream();
            byte[] buffer = new byte[8192];
            int n;
            while ((n = in.read(buffer)) > 0) {
                bos.write(buffer, 0, n);
            }
            // 先从流里读全字节再整体解码，避免多字节汉字被分块截断
            return new String(bos.toByteArray(), StandardCharsets.UTF_8).trim();
        } catch (Exception e) {
            log.error("提示词兜底资源读取失败：{}（若 app_report_prompt 里已配置该提示词，不影响）", path, e);
            return "";
        }
    }
}
