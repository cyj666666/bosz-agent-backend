package com.suzhou.bank.service.data.collector.impl;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import com.suzhou.bank.entity.CollectorConfig;
import com.suzhou.bank.service.data.collector.DataCollector;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Base64;
import java.util.List;

/**
 * 文件上传采集器
 * <p>接收客户经理手动上传的数据文件（Excel/CSV/PDF），
 * 校验文件类型和大小后，将内容 Base64 编码存储。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Component
public class FileUploadCollector implements DataCollector {

    /**
     * 当前上传的文件内容缓存（供后续解析使用）
     */
    private final ThreadLocal<MultipartFile> uploadedFile = new ThreadLocal<>();

    @Override
    public String getType() {
        return "FILE_UPLOAD";
    }

    /**
     * 常规采集流程（由调度触发），文件上传场景不走此路径。
     * 实际收集通过 {@link #collectFromUpload} 执行。
     */
    @Override
    public String collect(CollectorConfig config) {
        MultipartFile file = uploadedFile.get();
        if (file == null) {
            throw new RuntimeException("FILE_UPLOAD 采集需要调用 collectFromUpload 方法传入文件");
        }
        return collectFromUpload(config, file);
    }

    /**
     * 从上传的文件中采集数据
     *
     * @param config 采集器配置
     * @param file   上传的文件
     * @return 文件内容（文本按UTF-8解码，二进制转Base64）
     */
    public String collectFromUpload(CollectorConfig config, MultipartFile file) {
        try {
            JSONObject cfg = JSON.parseObject(config.getConfigJson());
            JSONArray allowedExts = cfg.getJSONArray("allowedExtensions");
            long maxSizeMB = cfg.getLongValue("maxFileSizeMB", 50);

            // 校验扩展名
            String originalName = file.getOriginalFilename();
            if (allowedExts != null && !allowedExts.isEmpty()) {
                boolean matched = false;
                for (Object ext : allowedExts) {
                    if (originalName != null && originalName.toLowerCase().endsWith(String.valueOf(ext).toLowerCase())) {
                        matched = true;
                        break;
                    }
                }
                if (!matched) {
                    throw new IllegalArgumentException("不支持的文件类型: " + originalName
                            + "，允许: " + allowedExts);
                }
            }

            // 校验大小
            if (file.getSize() > maxSizeMB * 1024 * 1024) {
                throw new IllegalArgumentException("文件过大: " + (file.getSize() / 1024 / 1024)
                        + "MB，限制: " + maxSizeMB + "MB");
            }

            byte[] bytes = file.getBytes();
            String result;

            // 文本文件直接读，PDF等二进制转Base64
            String lowerName = originalName != null ? originalName.toLowerCase() : "";
            if (lowerName.endsWith(".xlsx") || lowerName.endsWith(".pdf") || lowerName.endsWith(".xls")) {
                result = Base64.getEncoder().encodeToString(bytes);
                log.info("FILE_UPLOAD 采集完成（二进制）, file={}, base64Size={}", originalName, result.length());
            } else {
                result = new String(bytes, StandardCharsets.UTF_8);
                log.info("FILE_UPLOAD 采集完成, file={}, textSize={}", originalName, result.length());
            }

            return result;
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            log.error("FILE_UPLOAD 采集失败", e);
            throw new RuntimeException("FILE_UPLOAD 采集失败: " + e.getMessage(), e);
        } finally {
            uploadedFile.remove();
        }
    }

    /**
     * 设置当前请求中的上传文件（供 Controller 传入）
     */
    public void setUploadedFile(MultipartFile file) {
        this.uploadedFile.set(file);
    }

    @Override
    public boolean validateConfig(String configJson) {
        try {
            JSONObject cfg = JSON.parseObject(configJson);
            return cfg.containsKey("allowedExtensions");
        } catch (Exception e) {
            return false;
        }
    }
}
