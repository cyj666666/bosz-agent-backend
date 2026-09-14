package com.suzhou.bank.agent.config;

import javax.servlet.http.HttpServletRequest;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpHeaders;
import org.springframework.http.InvalidMediaTypeException;
import org.springframework.http.MediaType;
import org.springframework.util.CollectionUtils;
import org.springframework.util.InvalidMimeTypeException;
import org.springframework.web.HttpMediaTypeNotAcceptableException;
import org.springframework.web.accept.ContentNegotiationStrategy;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.servlet.config.annotation.ContentNegotiationConfigurer;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.util.Arrays;
import java.util.List;

/**
 * 迁移说明：本类平移自 amar-agent-server 的
 * {@code org.jeecg.modules.agent.configuration.SuitablePythonHttpSSEWebConfiguration}，
 * 用于兼容"Python 侧 SSE 客户端"的 Accept 头。
 *
 * <p><b>它解决什么问题</b>：标准的 Spring {@code ContentNegotiationStrategy} 会按请求的
 * {@code Accept} 头做媒体类型协商，协商不到就抛 406。而这些 Python 客户端发出的
 * {@code Accept} 头不规范（或干脆没有），导致 SSE 接口在进入 Controller 之前就被拦掉。
 * 本类把 4 个流式接口的协商结果直接固定为 {@code MediaType.ALL}，绕过对该头的严格校验。</p>
 *
 * <p><b>迁移改造点（共 3 处）</b>：</p>
 * <ol>
 *   <li><b>路径前缀</b>：源工程这 4 个路径是裸路径（源工程靠 context-path 区分）。
 *       本工程给 {@code AgentPromptController} 加了类级 {@code /api/agent} 前缀，
 *       因此这里必须同步补上——{@code pathInfo} 比对的是"去掉 contextPath 的 URI"，
 *       不同步改会导致这段适配【静默失效】，症状是很难定位的 406。</li>
 *   <li><b>{@code jakarta} → {@code javax}</b>：宿主是 Spring Boot 2.7 / Java 8。</li>
 *   <li><b>{@code List.of} → {@code Arrays.asList}</b>：{@code List.of} 是 Java 9+ API。</li>
 * </ol>
 *
 * <p><b>与宿主的关系</b>：{@code WebMvcConfigurer} 可以有多个实现，Spring 会依次调用。
 * 宿主自己的 {@code WebMvcConfig} 只注册了鉴权拦截器、没有配置内容协商，
 * 所以本类的 {@code configureContentNegotiation} 是唯一来源，不会被覆盖。</p>
 */
@Configuration
public class SuitablePythonHttpSSEWebConfiguration implements WebMvcConfigurer {

    /**
     * 迁移改造点：源工程为 {@code "/callLlm", "/applyPrompt", "/get", "/get/prompt"}，
     * 本工程统一加 {@code /api/agent} 前缀（与 AgentPromptController 的类级映射一致）。
     */
    private static final List<String> ALL_LIST = Arrays.asList(
            "/api/agent/callLlm", "/api/agent/applyPrompt", "/api/agent/get", "/api/agent/get/prompt");

    @Override
    public void configureContentNegotiation(ContentNegotiationConfigurer configurer) {
        configurer.strategies(Arrays.asList(new SuitablePythonHttpSSEStrategy()));
    }

    /**
     * 内容协商策略：命中 {@link #ALL_LIST} 的路径一律返回 {@code MediaType.ALL}，
     * 其余路径沿用 Spring 的默认行为（解析 Accept 头 + 按特异性排序）。
     */
    public static class SuitablePythonHttpSSEStrategy implements ContentNegotiationStrategy {

        @Override
        public List<MediaType> resolveMediaTypes(NativeWebRequest request) throws HttpMediaTypeNotAcceptableException {
            HttpServletRequest req = request.getNativeRequest(HttpServletRequest.class);
            String contextPath = req.getContextPath();
            String requestURI = req.getRequestURI();
            String pathInfo = null;
            if (contextPath != null && requestURI != null && requestURI.startsWith(contextPath)) {
                pathInfo = requestURI.substring(requestURI.indexOf(contextPath) + contextPath.length());
            }
            if (ALL_LIST.contains(pathInfo)) {
                return Arrays.asList(MediaType.ALL);
            }

            String[] headerValueArray = request.getHeaderValues(HttpHeaders.ACCEPT);
            if (headerValueArray == null) {
                return MEDIA_TYPE_ALL_LIST;
            }

            List<String> headerValues = Arrays.asList(headerValueArray);
            try {
                List<MediaType> mediaTypes = MediaType.parseMediaTypes(headerValues);
                // 迁移改造点：源工程（Spring 6）用的是 MimeTypeUtils.sortBySpecificity，
                // 那是泛型方法 <T extends MimeType>；Spring 5.3 的同名方法签名是
                // void sortBySpecificity(List<MimeType>)，List<MediaType> 传不进去（编译报错）。
                // 改用 MediaType.sortBySpecificity(List<MediaType>) —— 各版本都有、语义完全一致。
                MediaType.sortBySpecificity(mediaTypes);
                return !CollectionUtils.isEmpty(mediaTypes) ? mediaTypes : MEDIA_TYPE_ALL_LIST;
            } catch (InvalidMediaTypeException | InvalidMimeTypeException ex) {
                throw new HttpMediaTypeNotAcceptableException(
                        "Could not parse 'Accept' header " + headerValues + ": " + ex.getMessage());
            }

        }
    }
}
