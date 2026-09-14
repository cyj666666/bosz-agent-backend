package com.suzhou.bank.agent.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import com.suzhou.bank.agent.model.vo.SysCategoryModel;
import com.suzhou.bank.agent.model.vo.TreeSelectModel;
import com.suzhou.bank.agent.entity.SysCategory;

import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * @Description: 分类字典
 * @Author: jeecg-boot
 * @Date: 2019-05-29
 * @Version: V1.0
 */
@Mapper
public interface SysCategoryMapper extends BaseMapper<SysCategory> {

    List<TreeSelectModel> queryListByPid(@Param("pid") String pid, @Param("query") Map<String, String> query);

    List<SysCategoryModel> queryList(@Param("pid") String pid);

    @Select("SELECT ID FROM sys_category WHERE CODE = #{code,jdbcType=VARCHAR} AND param_status = 'Y'")
    String queryIdByCode(@Param("code") String code);

    @Select("select * from sys_category where pid in (select id from sys_category where code like 'X02%' and param_value = #{value,jdbcType=VARCHAR}) and param_status = 'Y'")
    List<SysCategory> getListByType(@Param("value") String value);

    List<SysCategory> getCurrentByValueList(@Param("valueList") Set<String> valueList);
}
