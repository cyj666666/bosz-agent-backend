package com.suzhou.bank.agent.model.vo;

import java.util.List;

/**
 * @Author qinfeng
 * @Date 2020/2/19 12:01
 * @Description:
 * @Version 1.0
 */
public class SysCategoryModel {

    private String id;

    private String pid;

    private String name;

    private String code;

    private String paramValue;

    private String keyword;

    private String hitIndependently;

    private String paramDesc;

    private String sampleQuestion;

    public String getSampleQuestion() {
        return sampleQuestion;
    }

    public void setSampleQuestion(String sampleQuestion) {
        this.sampleQuestion = sampleQuestion;
    }

    public String getKeyword() {
        return keyword;
    }

    public void setKeyword(String keyword) {
        this.keyword = keyword;
    }

    public String getHitIndependently() {
        return hitIndependently;
    }

    public void setHitIndependently(String hitIndependently) {
        this.hitIndependently = hitIndependently;
    }

    private List<SysCategoryModel> children;

    public List<SysCategoryModel> getChildren() {
        return children;
    }

    public void setChildren(List<SysCategoryModel> children) {
        this.children = children;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getPid() {
        return pid;
    }

    public void setPid(String pid) {
        this.pid = pid;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getParamValue() {
        return paramValue;
    }

    public void setParamValue(String paramValue) {
        this.paramValue = paramValue;
    }

    public String getParamDesc() {
        return paramDesc;
    }

    public void setParamDesc(String paramDesc) {
        this.paramDesc = paramDesc;
    }
}
