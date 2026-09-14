package com.suzhou.bank.agent.model.dto;

import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
public class DataReviewDTO {

    // 表头信息
    public List<String> tableHeaders;

    // 表数据信息
    public List<Map<String, Object>> dataList;

    //状态码
    public String code;

    //描述
    public String msg;
}

