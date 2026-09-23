package com.suzhou.bank.controller;

import com.suzhou.bank.common.Result;
import com.suzhou.bank.entity.report.AppReportPrompt;
import com.suzhou.bank.service.report.ai.ReportPromptService;
import com.suzhou.bank.service.report.model.ReportPromptUpdateRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 通用提示词管理接口（2026-09-23 测试反馈 #4）
 *
 * <p>对应前端「系统管理 → 通用提示词管理」页面：<b>只读列表 + 只改系统提示词</b>，
 * 刻意<b>不提供</b>新增 / 删除 —— 提示词条目按 {@code promptCode} 与代码里的场景一一对应
 * （{@code AI_FULL_ANALYSIS} / {@code WARNING_ADVICE}），增删会让「代码取用键」与
 * 「表里配置项」失去对应关系，属于配置事故高发区。</p>
 *
 * <p>🔴 <b>权限：admin-only</b>。在 {@code config/AuthInterceptor} 里与
 * {@code /api/user/**}、{@code /api/role/**}、{@code /api/agent/roleAuth/**} 同一条判定，
 * 需角色 {@code menu_permissions} 含系统管理菜单键之一（或 {@code role_code = admin} 兜底）。</p>
 *
 * <p>⚠️ <b>为什么放在宿主 report 模块、而不是 agent 模块</b>：表 {@code app_report_prompt} 的
 * 实体 / Mapper / 取用服务（{@link ReportPromptService}）都已存在于宿主，复用即可；
 * agent 模块刻意不反向依赖宿主 entity/mapper（见 {@code AgentRoleAuthController} 同类说明），
 * 若放进去就得为同一张表再复制一套实体与 Mapper，纯属重复。</p>
 *
 * <p>⚠️ <b>改完立即生效、无需重启</b>：{@link ReportPromptService#resolve} 每次调用都重新查表。</p>
 *
 * @author 曹陆宇
 * @since 1.0.0
 */
@Slf4j
@RestController
@RequestMapping("/api/report/prompt")
@RequiredArgsConstructor
public class ReportPromptConfigController {

    private final ReportPromptService reportPromptService;

    /**
     * 提示词列表
     *
     * <p>返回整行（前端只用 提示词名称 / 系统提示词 / 备注 / 创建时间 / 更新时间 五列，
     * 但编辑弹框需要回显整段 {@code systemPrompt}）—— 库里目前只有 2 条场景记录，
     * 不做分页。</p>
     */
    @GetMapping("/list")
    public Result<List<AppReportPrompt>> list() {
        return Result.ok(reportPromptService.listAll());
    }

    /**
     * 更新系统提示词
     *
     * <p>只改 {@code systemPrompt} + {@code updateTime} 两列，其余字段一律不动
     * （{@code promptCode} 是取用键、{@code userPromptTemplate} 有 {@code {material}}
     * 占位约定，都不该由界面改）。</p>
     *
     * @param request 请求体（id + systemPrompt）
     */
    @PostMapping("/update")
    public Result<Void> update(@RequestBody ReportPromptUpdateRequest request) {
        if (request == null || request.getId() == null) {
            return Result.fail("缺少提示词 id，无法定位要修改的记录");
        }
        try {
            boolean updated = reportPromptService.updateSystemPrompt(request.getId(), request.getSystemPrompt());
            if (!updated) {
                return Result.fail("未找到该提示词记录（可能已被删除）");
            }
            return Result.ok();
        } catch (Exception e) {
            // 落库异常要留日志：这是配置类写操作，出问题需要能追溯到具体 id
            log.error("更新提示词失败 id={} err={}", request.getId(), e.getMessage(), e);
            return Result.fail("保存失败：" + e.getMessage());
        }
    }
}
