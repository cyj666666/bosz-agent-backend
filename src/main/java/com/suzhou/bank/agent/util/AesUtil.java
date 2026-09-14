package com.suzhou.bank.agent.util;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;

public class AesUtil {

    private static final String APIKEY_STRING = System.getProperty("aes.util.key", "aezXcjomj#1eW6lq"); // 从系统属性获取API密钥
    private static final String ALGORITHM = "AES";
    private static final String TRANSFORMATION = "AES/ECB/NoPadding";
    private static final String GCM_TRANSFORMATION = "AES/GCM/NoPadding";
    private static final int GCM_IV_LENGTH = 12;
    private static final int GCM_TAG_LENGTH_BITS = 128;
    // 新版密文前缀，用于区分 GCM 密文与旧 ECB 密文
    private static final String GCM_PREFIX = "{GCM}";

    /**
     * AES 加密（GCM 模式，随机 IV + 认证标签）
     * 输出格式：{GCM} + Base64(iv || ciphertext)
     */
    public static String encrypt(String data) {
        try {
            SecretKeySpec secretKey = new SecretKeySpec(APIKEY_STRING.getBytes(StandardCharsets.UTF_8), ALGORITHM);
            byte[] iv = new byte[GCM_IV_LENGTH];
            new SecureRandom().nextBytes(iv);
            Cipher cipher = Cipher.getInstance(GCM_TRANSFORMATION);
            cipher.init(Cipher.ENCRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv));
            byte[] encryptedBytes = cipher.doFinal(data.getBytes(StandardCharsets.UTF_8));

            byte[] combined = new byte[iv.length + encryptedBytes.length];
            System.arraycopy(iv, 0, combined, 0, iv.length);
            System.arraycopy(encryptedBytes, 0, combined, iv.length, encryptedBytes.length);
            return GCM_PREFIX + Base64.getEncoder().encodeToString(combined);
        } catch (Exception e) {
            throw new RuntimeException("加密失败", e);
        }
    }

    /**
     * AES 解密：带 {@value GCM_PREFIX} 前缀的新版密文走 GCM 解密；
     * 无前缀的旧版密文回退 ECB 解密（兼容前端存量密文）。
     */
    public static String decrypt(String encryptedData) {
        try {
            if (encryptedData != null && encryptedData.startsWith(GCM_PREFIX)) {
                return decryptGcm(encryptedData.substring(GCM_PREFIX.length()));
            }
            return decryptEcb(encryptedData);
        } catch (Exception e) {
            throw new RuntimeException("解密失败", e);
        }
    }

    /**
     * GCM 解密
     */
    private static String decryptGcm(String base64Data) throws Exception {
        byte[] combined = Base64.getDecoder().decode(base64Data);
        byte[] iv = new byte[GCM_IV_LENGTH];
        byte[] encryptedBytes = new byte[combined.length - GCM_IV_LENGTH];
        System.arraycopy(combined, 0, iv, 0, GCM_IV_LENGTH);
        System.arraycopy(combined, GCM_IV_LENGTH, encryptedBytes, 0, encryptedBytes.length);

        SecretKeySpec secretKey = new SecretKeySpec(APIKEY_STRING.getBytes(StandardCharsets.UTF_8), ALGORITHM);
        Cipher cipher = Cipher.getInstance(GCM_TRANSFORMATION);
        cipher.init(Cipher.DECRYPT_MODE, secretKey, new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv));
        byte[] decryptedBytes = cipher.doFinal(encryptedBytes);
        return new String(decryptedBytes, StandardCharsets.UTF_8);
    }

    /**
     * 旧版 ECB 解密（对应 JavaScript 的 decrypt 函数），保留用于兼容存量密文
     */
    private static String decryptEcb(String encryptedData) throws Exception {
        byte[] encryptedBytes = Base64.getDecoder().decode(encryptedData);

        SecretKeySpec secretKey = new SecretKeySpec(APIKEY_STRING.getBytes(StandardCharsets.UTF_8), ALGORITHM);
        Cipher cipher = Cipher.getInstance(TRANSFORMATION);
        cipher.init(Cipher.DECRYPT_MODE, secretKey);

        byte[] decryptedBytes = cipher.doFinal(encryptedBytes);
        // 移除补零的字节
        String result = new String(decryptedBytes, StandardCharsets.UTF_8);
        return result.replaceAll("\\x00+$", "");
    }

    public static void main(String[] args) {
        String originalText = "Amars0ft01!";
        System.out.println("Original Text: " + originalText);

        // 加密（新版 GCM）
        String encryptedText = encrypt(originalText);
        System.out.println("Encrypted Text: " + encryptedText);

        // 解密
        String decryptedText = decrypt(encryptedText);
        System.out.println("Decrypted Text: " + decryptedText);
    }
}
