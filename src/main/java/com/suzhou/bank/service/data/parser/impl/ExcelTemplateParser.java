package com.suzhou.bank.service.data.parser.impl;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.JSONObject;
import com.suzhou.bank.service.data.parser.DataParser;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Component;

import java.io.ByteArrayInputStream;
import java.util.ArrayList;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Excel 模板解析器
 * <p>按行列位置从固定格式 Excel 中提取数据。
 * 适用于税务申报表、社保清单等每年格式不变的报表。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Slf4j
@Component
public class ExcelTemplateParser implements DataParser {

    @Override
    public String getType() {
        return "EXCEL_TEMPLATE";
    }

    @Override
    public List<Map<String, Object>> parse(String rawData, String parseConfig, Long customerId) {
        JSONObject cfg = JSON.parseObject(parseConfig);
        String sheetName = cfg.getString("sheetName");
        int startRow = cfg.getIntValue("startRow", 1);
        JSONObject columnMapping = cfg.getJSONObject("columnMapping");

        if (columnMapping == null || columnMapping.isEmpty()) {
            log.warn("EXCEL_TEMPLATE 解析配置中无 columnMapping");
            return new ArrayList<>();
        }

        List<Map<String, Object>> result = new ArrayList<>();

        try (Workbook workbook = new XSSFWorkbook(new ByteArrayInputStream(decodeRawData(rawData)))) {
            Sheet sheet = sheetName != null ? workbook.getSheet(sheetName) : workbook.getSheetAt(0);
            if (sheet == null) {
                log.error("EXCEL_TEMPLATE 未找到 sheet: {}", sheetName);
                return result;
            }

            FormulaEvaluator evaluator = workbook.getCreationHelper().createFormulaEvaluator();
            DataFormatter formatter = new DataFormatter();

            for (int rowIdx = startRow - 1; rowIdx <= sheet.getLastRowNum(); rowIdx++) {
                Row row = sheet.getRow(rowIdx);
                if (row == null) continue;

                Map<String, Object> indicator = new LinkedHashMap<>();
                indicator.put("customerId", customerId);
                boolean hasValue = false;

                for (String colLetter : columnMapping.keySet()) {
                    int colIdx = columnLetterToIndex(colLetter);
                    Cell cell = row.getCell(colIdx);
                    String indicatorKey = columnMapping.getString(colLetter);

                    if (cell != null) {
                        String val = formatter.formatCellValue(cell, evaluator);
                        if (val != null && !val.trim().isEmpty()) {
                            indicator.put(indicatorKey, val);
                            hasValue = true;
                        }
                    }
                }

                if (hasValue) {
                    result.add(indicator);
                } else {
                    break; // 遇到全空行停止
                }
            }

            log.info("EXCEL_TEMPLATE 解析完成, sheet={}, startRow={}, extractedCount={}",
                    sheetName, startRow, result.size());
        } catch (Exception e) {
            log.error("EXCEL_TEMPLATE 解析失败", e);
        }
        return result;
    }

    /**
     * 将原始数据解码为字节数组（支持 Base64 或普通字符串）
     */
    private byte[] decodeRawData(String rawData) {
        try {
            return Base64.getDecoder().decode(rawData);
        } catch (IllegalArgumentException e) {
            return rawData.getBytes();
        }
    }

    /**
     * 列字母转索引：A→0, B→1, ..., Z→25, AA→26
     */
    private int columnLetterToIndex(String letter) {
        letter = letter.toUpperCase();
        int idx = 0;
        for (char c : letter.toCharArray()) {
            idx = idx * 26 + (c - 'A' + 1);
        }
        return idx - 1;
    }
}
