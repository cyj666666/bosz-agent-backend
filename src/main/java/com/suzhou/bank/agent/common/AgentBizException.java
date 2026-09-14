package com.suzhou.bank.agent.common;

/**
 * agent 模块业务异常
 *
 * <p><b>为什么单独定义一个异常</b>：源工程（amar-agent-server）统一抛
 * {@code org.jeecg.common.exception.JeecgBootException}，那是 JeecgBoot 框架的类，
 * 宿主工程没有也不应该有。agent 模块自带一个，
 * 使模块搬迁时不依赖任何框架私有异常类型。</p>
 *
 * <p>继承 {@link RuntimeException}（非受检），与源工程行为一致，
 * 因此从源工程平移过来的代码调用处无需增加 try/catch。</p>
 */
public class AgentBizException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    public AgentBizException(String message) {
        super(message);
    }

    public AgentBizException(String message, Throwable cause) {
        super(message, cause);
    }

    public AgentBizException(Throwable cause) {
        super(cause);
    }
}
