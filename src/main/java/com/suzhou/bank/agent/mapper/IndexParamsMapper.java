package com.suzhou.bank.agent.mapper;

import com.alibaba.fastjson.JSONObject;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import com.suzhou.bank.agent.entity.IndexParamsEntity;

import java.util.List;


@Mapper
public interface IndexParamsMapper extends BaseMapper<IndexParamsEntity> {

    /**
     * 取指定表的列名列表
     *
     * <p><b>迁移改造点</b>：源实现写的是
     * {@code where table_schema = (select database())}，其中 {@code database()}
     * 是 MySQL 专有函数，GaussDB/openGauss 上不存在、执行会直接报错。
     * 现改为 PG 语法 {@code current_schema()}，并用 {@code lower()} 忽略表名大小写
     * （PG 的 information_schema 里表名统一以小写存储）。</p>
     */
    @Select("select column_name from information_schema.columns "
            + "where table_schema = current_schema() and lower(table_name) = lower(#{tableName})")
    List<String> selectColumns(@Param("tableName") String tableName);

    @Select("select paramno from index_params where scripttype = 'Api' and intfno is null union select paramno from index_params where scripttype != 'Api' or scripttype is null")
    List<String> getAllParamNoList();

    @Select("select paramid, paramno, paramname, parentparamno,script, intfparams, scripttype from index_params where (script is not null and script != '' and script like '%relateIndex\":{%') or (intfparams is not null and intfparams != '' and intfparams like '%relateIndex\":{\"%')")
    List<IndexParamsEntity> getHavingRelationIndexList();

    @Select("select b.prompt_template, b.large_model_code \n" +
            "        from prompt_verify_scene_info a, prompt_verify_scene_relate_prompt_info b\n" +
            "        where a.id=b.scene_id\n" +
            "        and b.large_model_code is not null and b.large_model_code !=''\n" +
            "        and a.scene_name is not null and a.scene_name != ''\n" +
            "        and b.prompt_template is not null and b.prompt_template != ''\n" +
            "        and a.scene_name = '大模型评估'\n" +
            "        limit 1")
    JSONObject getPromptTemplate();

    List<IndexParamsEntity> selectRelateIndexParams(@Param("knowledgeIdList") List<String> knowledgeIdList);

    List<IndexParamsEntity> selectAllGroupIndexList(@Param("paramNoListStr") String paramNoListStr, @Param("paramNoList") List<String> paramNoList);
}
