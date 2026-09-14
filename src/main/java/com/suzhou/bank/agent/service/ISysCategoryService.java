package com.suzhou.bank.agent.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.suzhou.bank.agent.common.AgentBizException;
import com.suzhou.bank.agent.model.vo.SysCategoryModel;
import com.suzhou.bank.agent.model.vo.TreeSelectModel;
import com.suzhou.bank.agent.entity.SysCategory;

import java.util.List;

/**
 * @Description: 分类字典
 * @Author: jeecg-boot
 * @Date: 2019-05-29
 * @Version: V1.0
 */
public interface ISysCategoryService extends IService<SysCategory> {

    public static final String ROOT_PID_VALUE = "0";

    void addSysCategory(SysCategory sysCategory);

    void updateSysCategory(SysCategory sysCategory);

    List<TreeSelectModel> queryListByCode(String pcode) throws AgentBizException;

    List<TreeSelectModel> queryListByPid(String pid);

    List<SysCategoryModel> queryList(String pid);

    String queryIdByCode(String code);

    void deleteSysCategory(String ids);

    List<String> loadDictItem(String ids);

    List<String> loadDictItem(String ids, boolean delNotExist);

    boolean doubleCheckDictCode(String id, String pid, String paramValue);

}
