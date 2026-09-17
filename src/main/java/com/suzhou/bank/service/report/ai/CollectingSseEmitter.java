package com.suzhou.bank.service.report.ai;

import com.alibaba.fastjson.JSONObject;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * 「只收集、不外发」的 {@link SseEmitter}
 *
 * <p>用途：把**流式**大模型调用逐帧吐出的文本在服务端拼回整篇，用于落库类场景
 * （报告正文加工、风险要点总结等），而不是推给浏览器。</p>
 *
 * <h3>🔴 为什么报告链路必须走流式，而不是非流式</h3>
 * <p>本平台接的是 reasoning 模型（返回体里带 {@code reasoning_content}），
 * <b>思考 token 与正文 token 共用同一个 {@code max_tokens} 额度</b>。非流式时若思考把额度吃满，
 * 返回的是 {@code answer=""}（正文一个字都没有，而且<b>不报错</b>）——
 * 调用方一旦把空串回退成 {@code content}，就会把一大段提示词写进报告正文。</p>
 *
 * <p>2026-09-18 实测（{@code RPT-202603-001} 的 {@code tddkjcqk} 块）：
 * {@code prompt_tokens=10214}、{@code completion_tokens=10000}（正好顶满）、{@code answer=""}；
 * 而同一个 prompt 走流式则正文正常产出。流式边生成边吐，
 * <b>已经产出的正文不会因为总量截断而整段丢失</b>，这才是"保险"的来源。</p>
 *
 * <h3>实现要点</h3>
 * <p><b>只重写 {@code send(Object, MediaType)}，且不调用 {@code super}</b>：
 * 本对象不面向浏览器，没必要把数据塞进 Spring 的 handler / {@code earlySendAttempts}，
 * 也避免无 handler 时可能出现的堆积。</p>
 *
 * <p>帧的来源与格式（见 {@code OpenAiChatUtil#consumeStream}、{@code CallLlmUtil#finishEmitterWithError}）：</p>
 * <ul>
 *   <li><b>正常增量帧</b>：{@code send(JSONObject, MediaType.APPLICATION_JSON)}，{@code code=200}，
 *       文本在 {@code answer}（{@code knowledgeQuery=true}）或 {@code content}（{@code false}）里 —— 计入正文；</li>
 *   <li><b>非正常帧</b>：{@code send(String)}（错误提示 / {@code finished!} 结束标记），
 *       {@code mediaType} 为 {@code null} —— 只留痕，<b>绝不并入正文</b>。</li>
 * </ul>
 *
 * <p>🔴 帧里的 {@code JSONObject} 是 {@code OpenAiChatUtil} 用 <b>fastjson1</b>
 * （{@code com.alibaba.fastjson}）构造的，所以这里的 {@code instanceof} 必须用<b>同一个包</b>的
 * {@code JSONObject} —— 本工程里 fastjson1 / fastjson2 并存，
 * 用错版本的话 {@code instanceof} 恒为 false，表现为"一个字都收不到"且不报错。</p>
 *
 * @author cyj666666
 * @since 1.4.0
 */
@Slf4j
public class CollectingSseEmitter extends SseEmitter {

    /** 正常增量帧拼出来的正文 */
    private final StringBuilder text = new StringBuilder();

    /** 非正常帧（错误提示 / 结束标记）留痕，便于回答"为什么结果是空的" */
    private final StringBuilder notices = new StringBuilder();

    public CollectingSseEmitter() {
        // 与 sinkEmitter 口径一致：超时给 0，走容器默认；本对象不会真的挂到响应上
        super(0L);
    }

    /**
     * 截获一切外发数据
     *
     * <p>刻意<b>不调用 {@code super}</b> —— 收完即止，不往下游走。</p>
     */
    @Override
    public void send(Object object, MediaType mediaType) {
        if (mediaType != null && object instanceof JSONObject) {
            JSONObject frame = (JSONObject) object;
            String piece = frame.getString("answer");
            if (piece == null) {
                piece = frame.getString("content");
            }
            if (piece != null && !piece.isEmpty()) {
                text.append(piece);
            }
            return;
        }
        if (object != null) {
            notices.append(object);
        }
    }

    /** 收集到的正文（流式增量拼回来的整篇） */
    public String getText() {
        return text.toString();
    }

    /** 收集到的非正常帧文本（错误提示 / 结束标记），仅用于排查 */
    public String getNotices() {
        return notices.toString();
    }

    /** 当前累计字数（用于日志，不必先 toString） */
    public int textLength() {
        return text.length();
    }
}
