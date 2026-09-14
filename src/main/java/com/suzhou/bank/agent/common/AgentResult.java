package com.suzhou.bank.agent.common;

import lombok.Data;

/**
 * agent 模块统一响应体
 *
 * <p><b>为什么不复用宿主的 {@code com.suzhou.bank.common.Result}</b>：
 * agent 模块要求能整体搬迁/摘除，若复用宿主类型，搬迁时就要求目标工程必须存在同名同构的 Result，
 * 徒增耦合。这里自带一份，字段与宿主保持同构（{@code code/message/data}），
 * 因此前端两套接口可以共用同一套解包约定，不会混淆。</p>
 *
 * <p>返回格式：{@code {"code": 200, "message": "success", "data": ...}}</p>
 *
 * @param <T> 响应数据类型
 */
@Data
public class AgentResult<T> {

    /** 业务码：200 成功，其余为失败（与宿主 Result 口径一致） */
    private int code;

    /** 提示信息 */
    private String message;

    /** 响应数据 */
    private T data;

    private AgentResult(int code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    public static <T> AgentResult<T> ok(T data) {
        return new AgentResult<>(200, "success", data);
    }

    public static <T> AgentResult<T> ok() {
        return new AgentResult<>(200, "success", null);
    }

    public static <T> AgentResult<T> fail(String message) {
        return new AgentResult<>(500, message, null);
    }

    public static <T> AgentResult<T> fail(int code, String message) {
        return new AgentResult<>(code, message, null);
    }

    // ==================================================================================
    // 以下为「源工程兼容入口」，仅为让从 amar-agent-server 平移过来的代码零改写即可编译。
    //
    // 源工程用 JeecgBoot 的 org.jeecg.common.api.vo.Result，其静态工厂是 OK(...) / error(...)，
    // 且业务数据放在名为 result 的字段里。本类业务数据放在 data 字段里——
    // 两者序列化后的 JSON 结构不同（result vs data），这是前端要跟着适配的点。
    //
    // 保留这些方法名的收益：约 30 处调用点（Result.OK / Result.error）无需逐个改写，
    // 降低平移过程中的出错面。新写的 agent 代码建议直接用 ok()/fail()。
    // ==================================================================================

    /**
     * 兼容源工程 {@code Result.OK(T data)}
     */
    public static <T> AgentResult<T> OK(T data) {
        return new AgentResult<>(200, "success", data);
    }

    /**
     * 兼容源工程 {@code Result.OK()}
     */
    public static <T> AgentResult<T> OK() {
        return new AgentResult<>(200, "success", null);
    }

    /**
     * 兼容源工程 {@code Result.OK(String msg, T data)}
     */
    public static <T> AgentResult<T> OK(String msg, T data) {
        return new AgentResult<>(200, msg, data);
    }

    /**
     * 兼容源工程 {@code Result.OK(T data, Integer totalCount)}
     *
     * <p>注意：源实现里 totalCount 参数被注释掉、实际未使用（总数走 ListResult 返回），
     * 这里保持一致——参数被接收但忽略。</p>
     */
    public static <T> AgentResult<T> OK(T data, Integer totalCount) {
        return new AgentResult<>(200, "success", data);
    }

    /**
     * 兼容源工程 {@code Result.error(String msg, T data)}
     */
    public static <T> AgentResult<T> error(String msg, T data) {
        return new AgentResult<>(500, msg, data);
    }

    /**
     * 兼容源工程 {@code Result.error(String msg)}
     */
    public static AgentResult<Object> error(String msg) {
        return new AgentResult<>(500, msg, null);
    }

    /**
     * 兼容源工程 {@code Result.ERROR(String msg)}
     */
    public static <T> AgentResult<T> ERROR(String msg) {
        return new AgentResult<>(500, msg, null);
    }

    /**
     * 兼容源工程 {@code Result.error(int code, String msg)}
     */
    public static AgentResult<Object> error(int code, String msg) {
        return new AgentResult<>(code, msg, null);
    }

    /**
     * 兼容源工程实例方法 {@code Result.success(String message)}
     */
    public AgentResult<T> success(String message) {
        this.message = message;
        this.code = 200;
        return this;
    }

    /**
     * 无参构造
     *
     * <p>兼容源工程 {@code new Result<T>()} 的用法——源实现（尤其 {@code SysCategoryController}）
     * 大量采用"先 new、再 setSuccess/setResult"的写法，共 13 处。
     * 补上它可让这些代码零改写。</p>
     */
    public AgentResult() {
    }

    /**
     * 兼容源工程 {@code Result#setSuccess(boolean)}
     *
     * <p>语义映射：源工程的 {@code success} 是独立布尔字段，本类用 {@code code} 表达成功与否
     * （200 成功 / 500 失败）。这里做等价转换，避免源代码出现"success=true 但 code=0"的错位。</p>
     */
    public void setSuccess(boolean success) {
        this.code = success ? 200 : 500;
    }

    /**
     * 兼容源工程 {@code Result#setResult(T)}
     *
     * <p>源工程的业务数据字段叫 {@code result}，本类叫 {@code data}，此处做映射。
     * <b>注意</b>：刻意不提供对应的 {@code getResult()}——否则 fastjson 会在响应 JSON 里
     * 多输出一个 {@code result} 字段，污染前端契约（前端只认 {@code code/message/data}）。</p>
     */
    public void setResult(T data) {
        this.data = data;
    }

    /**
     * 兼容源工程实例方法 {@code Result#error500(String message)}
     */
    public AgentResult<T> error500(String message) {
        this.code = 500;
        this.message = message;
        return this;
    }
}
