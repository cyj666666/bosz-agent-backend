package com.suzhou.bank.agent.util;

import java.util.UUID;

/**
 * UUID 生成工具
 *
 * <p>替代源工程的 {@code org.jeecg.common.util.UUIDGenerator}（JeecgBoot 工具类）。</p>
 *
 * <p>源工程的 {@code generate()} 返回不带连字符的 32 位 UUID，
 * 本类保持一致——指标主键（{@code index_params.paramid}）就是按这个格式写入的，
 * 格式一变会影响与历史数据的比对。</p>
 */
public class UUIDGenerator {

    /**
     * 生成不带连字符的 32 位 UUID
     */
    public static String generate() {
        return UUID.randomUUID().toString().replace("-", "");
    }

    /**
     * 生成带连字符的标准 UUID
     */
    public static String generateWithDash() {
        return UUID.randomUUID().toString();
    }
}
