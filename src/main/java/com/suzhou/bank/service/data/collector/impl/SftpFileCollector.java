package com.suzhou.bank.service.data.collector.impl;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.suzhou.bank.entity.CollectorConfig;
import com.suzhou.bank.service.data.collector.DataCollector;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;
import java.util.Vector;

import com.jcraft.jsch.*;

/**
 * SFTP 文件采集器
 * <p>从合作方的 SFTP 服务器下载数据文件，按文件名模式匹配目标文件。
 * 适用于税务局、社保局等定期推送报表文件的场景。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Component
public class SftpFileCollector implements DataCollector {

    @Override
    public String getType() {
        return "SFTP_FILE";
    }

    @Override
    public String collect(CollectorConfig config) {
        JSONObject cfg = JSON.parseObject(config.getConfigJson());
        String host = cfg.getString("host");
        int port = cfg.getIntValue("port", 22);
        String username = cfg.getString("username");
        String password = cfg.getString("password");
        String remotePath = cfg.getString("remotePath");
        String filePattern = cfg.getString("filePattern");

        JSch jsch = new JSch();
        Session session = null;
        ChannelSftp sftp = null;

        try {
            session = jsch.getSession(username, host, port);
            session.setPassword(password);
            // 主机密钥校验：生产环境建议配置 known_hosts 文件路径
            String knownHosts = cfg.getString("knownHostsPath");
            if (knownHosts != null && !knownHosts.isEmpty()) {
                jsch.setKnownHosts(knownHosts);
                session.setConfig("StrictHostKeyChecking", "yes");
            } else {
                session.setConfig("StrictHostKeyChecking", "ask");
            }
            session.setTimeout(15000);
            session.connect();

            sftp = (ChannelSftp) session.openChannel("sftp");
            sftp.connect();

            List<ChannelSftp.LsEntry> entries = new Vector<>(sftp.ls(remotePath));
            StringBuilder result = new StringBuilder();
            int fileCount = 0;

            for (ChannelSftp.LsEntry entry : entries) {
                String name = entry.getFilename();
                if (".".equals(name) || "..".equals(name) || entry.getAttrs().isDir()) continue;

                if (matchPattern(name, filePattern)) {
                    InputStream is = sftp.get(remotePath + "/" + name);
                    String content = readInputStream(is);
                    result.append("=== ").append(name).append(" ===\n").append(content).append("\n");
                    fileCount++;
                }
            }

            log.info("SFTP_FILE 采集完成, host={}, path={}, fileCount={}, totalSize={}",
                    host, remotePath, fileCount, result.length());
            return result.toString();
        } catch (Exception e) {
            log.error("SFTP_FILE 采集失败, host={}, path={}", host, remotePath, e);
            throw new RuntimeException("SFTP_FILE 采集失败: " + e.getMessage(), e);
        } finally {
            if (sftp != null) sftp.disconnect();
            if (session != null) session.disconnect();
        }
    }

    private boolean matchPattern(String filename, String pattern) {
        if (pattern == null || pattern.isEmpty() || "*".equals(pattern)) return true;
        // 简单通配符匹配：*.xlsx, report_*.csv 等
        String regex = pattern.replace(".", "\\.").replace("*", ".*");
        return filename.matches(regex);
    }

    private String readInputStream(InputStream is) throws Exception {
        // 先尝试按二进制读，失败则按文本读
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        byte[] buf = new byte[4096];
        int n;
        while ((n = is.read(buf)) != -1) {
            bos.write(buf, 0, n);
        }
        byte[] bytes = bos.toByteArray();
        // 如果是纯文本文件（不含BOM头中的非文本字节），按UTF-8解码
        return new String(bytes, StandardCharsets.UTF_8);
    }

    @Override
    public boolean validateConfig(String configJson) {
        try {
            JSONObject cfg = JSON.parseObject(configJson);
            return cfg.containsKey("host") && cfg.containsKey("username")
                    && cfg.containsKey("remotePath");
        } catch (Exception e) {
            return false;
        }
    }
}
