package com.suzhou.bank.config;

import org.bouncycastle.jce.provider.BouncyCastleProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Cipher;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.Security;
import java.util.Base64;

/**
 * 国密 SM4 加解密服务
 * <p>供信贷系统跳转链接的参数加密/解密使用。算法参数：SM4/ECB/PKCS7，
 * 密钥为 UTF-8 文本，输出 Base64。SM4 密钥由尽调智能体统一提供，
 * 通过配置项 {@code credit.sm4-key} 注入（生产建议用环境变量，避免明文入库/入 git）。
 * BouncyCastle Provider 在初始化时注册。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Component
public class Sm4Service {

    private static final String TRANSFORMATION = "SM4/ECB/PKCS5Padding";
    private static final String ALGORITHM = "SM4";

    private static BouncyCastleProvider provider() {
        BouncyCastleProvider p = (BouncyCastleProvider) Security.getProvider(BouncyCastleProvider.PROVIDER_NAME);
        if (p == null) {
            p = new BouncyCastleProvider();
            Security.addProvider(p);
        }
        return p;
    }

    private final byte[] key;

    public Sm4Service(@Value("${credit.sm4-key}") String sm4Key) {
        provider();
        if (sm4Key == null || sm4Key.trim().isEmpty()) {
            throw new IllegalStateException("SM4 密钥未配置，请设置 credit.sm4-key");
        }
        this.key = sm4Key.trim().getBytes(StandardCharsets.UTF_8);
    }

    /**
     * SM4/ECB/PKCS7 加密
     *
     * @param plain 明文
     * @return Base64 密文
     */
    public String encrypt(String plain) throws Exception {
        if (plain == null) {
            return null;
        }
        Cipher cipher = Cipher.getInstance(TRANSFORMATION, provider());
        cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key, ALGORITHM));
        return Base64.getEncoder().encodeToString(cipher.doFinal(plain.getBytes(StandardCharsets.UTF_8)));
    }

    /**
     * SM4/ECB/PKCS7 解密
     *
     * @param base64Cipher Base64 密文
     * @return 明文
     */
    public String decrypt(String base64Cipher) throws Exception {
        if (base64Cipher == null || base64Cipher.trim().isEmpty()) {
            return null;
        }
        byte[] data = Base64.getDecoder().decode(normalizeBase64(base64Cipher));
        if (data.length == 0) {
            throw new IllegalArgumentException("SM4 密文为空");
        }
        if (data.length % 16 != 0) {
            throw new IllegalArgumentException(
                    "SM4 密文长度非法（base64 解码后 " + data.length + " 字节，不是 16 的整数倍），"
                            + "密文很可能在 URL 传输中被截断/丢失字符，请核对传入的 cipher 与加密返回的是否逐字符一致");
        }
        Cipher cipher = Cipher.getInstance(TRANSFORMATION, provider());
        cipher.init(Cipher.DECRYPT_MODE, new SecretKeySpec(key, ALGORITHM));
        return new String(cipher.doFinal(data), StandardCharsets.UTF_8);
    }

    /**
     * 归一化 Base64 密文，容忍「密文放入 URL 传输」引入的变形，使同一份密文无论是否被 URL 编码、
     * 用标准还是 URL 安全 Base64，都能正确解码：
     * <ul>
     *   <li>空格→'+'：标准/URL 安全 Base64 本身不含空格，出现空格必是 URL（form-urlencoded）解码把 '+' 变成了空格(0x20)，此处还原。
     *       <b>必须在去除/修剪空白之前做</b>，否则密文首尾的空格（实为被解码的 '+'）会被吃掉而丢失字符；</li>
     *   <li>去除其余空白（换行/制表/首尾空白等）；</li>
     *   <li>URL 安全字符转标准：'-'→'+'、'_'→'/'；</li>
     *   <li>补齐 '=' padding。</li>
     * </ul>
     */
    private static String normalizeBase64(String raw) {
        // 先把被 URL 解码成空格的 '+' 还原，再做空白清理（顺序不能反，见 javadoc）
        String b64 = raw.replace(" ", "+");
        b64 = b64.replaceAll("\\s", "");
        b64 = b64.replace('-', '+').replace('_', '/');
        switch (b64.length() % 4) {
            case 2:
                b64 += "==";
                break;
            case 3:
                b64 += "=";
                break;
            default:
                break;
        }
        return b64;
    }
}
