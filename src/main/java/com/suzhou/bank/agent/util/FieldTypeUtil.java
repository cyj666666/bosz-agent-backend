package com.suzhou.bank.agent.util;

import org.springframework.util.StringUtils;

/**
 * 不同数据库之间字段类型处理
 */
public class FieldTypeUtil {

    public static String handMysqlEmpty(String empty) {
        if ("N".equalsIgnoreCase(empty)) {
            return "NOT NULL";
        }
        return "DEFAULT NULL";
    }

    public static String handOracleEmpty(String empty) {
        if ("N".equalsIgnoreCase(empty)) {
            return "NOT NULL ENABLE";
        }
        return "DEFAULT NULL";
    }

    public static String handleMysqlFieldType(String fieldType, String fieldLength) {
        if ("STRING".equalsIgnoreCase(fieldType)) {
            return "VARCHAR(100)";
        }

        if ("CLOB".equalsIgnoreCase(fieldType)
                || "NCLOB".equalsIgnoreCase(fieldType)) {
            return "TEXT";
        }

        if ("BIGINT".equalsIgnoreCase(fieldType)
                || "DATETIME".equalsIgnoreCase(fieldType)
                || "TIMESTAMP".equalsIgnoreCase(fieldType)
                || "DATE".equalsIgnoreCase(fieldType)
                || "LONGTEXT".equalsIgnoreCase(fieldType)
                || "TINYTEXT".equalsIgnoreCase(fieldType)
                || "TEXT".equalsIgnoreCase(fieldType)
                || "BLOB".equalsIgnoreCase(fieldType)
                || "LONGBLOB".equalsIgnoreCase(fieldType)
                || "MEDIUMBLOB".equalsIgnoreCase(fieldType)) {
            return fieldType;
        }

        if (StringUtils.isEmpty(fieldLength)
                || "NULL".equalsIgnoreCase(fieldLength)) {
            return fieldType;
        }

        if ("varchar2".equalsIgnoreCase(fieldType)
                || "nvarchar2".equalsIgnoreCase(fieldType)) {
            fieldType = "varchar";
        }

        if ("number".equalsIgnoreCase(fieldType)) {
            fieldType = "int";
        }

        return fieldType + "(" + fieldLength + ")";
    }

    public static String handleOracleFieldType(String fieldType, String fieldLength) {
        if ("STRING".equalsIgnoreCase(fieldType)) {
            return "VARCHAR2(100)";
        }

        if ("CLOB".equalsIgnoreCase(fieldType)) {
            return "CLOB";
        }

        if ("BIGINT".equalsIgnoreCase(fieldType)) {
            return "NUMBER(19,0)";
        }

        if ("DATETIME".equalsIgnoreCase(fieldType)
                || "TIME".equalsIgnoreCase(fieldType)
                || "TIMESTAMP".equalsIgnoreCase(fieldType)
                || "DATE".equalsIgnoreCase(fieldType)) {
            return "DATE";
        }

        if ("LONGTEXT".equalsIgnoreCase(fieldType)
                || "TINYTEXT".equalsIgnoreCase(fieldType)
                || "TEXT".equalsIgnoreCase(fieldType)) {
            return "CLOB";
        }

        if ("BLOB".equalsIgnoreCase(fieldType)
                || "LONGBLOB".equalsIgnoreCase(fieldType)
                || "MEDIUMBLOB".equalsIgnoreCase(fieldType)) {
            return "BLOB";
        }

        if (StringUtils.isEmpty(fieldLength)
                || "NULL".equalsIgnoreCase(fieldLength)) {
            return fieldType;
        }

        if ("VARCHAR".equalsIgnoreCase(fieldType)
                || "ENUM".equalsIgnoreCase(fieldType)) {
            fieldType = "VARCHAR2";
        }

        if ("VARCHAR".equalsIgnoreCase(fieldType)
                || "ENUM".equalsIgnoreCase(fieldType)) {
            fieldType = "VARCHAR2";
        }

        if ("INT".equalsIgnoreCase(fieldType)
                || "YEAR".equalsIgnoreCase(fieldType)
                || "BIGINT".equalsIgnoreCase(fieldType)
                || "INTEGER".equalsIgnoreCase(fieldType)) {
            fieldType = "NUMBER";
        }

        return fieldType + "(" + fieldLength + ")";
    }

    public static String getStr(Object obj) {
        String str = String.valueOf(obj);
        if ("null".equalsIgnoreCase(str) || StringUtils.isEmpty(str)) {
            return "";
        }

        return str;
    }

}
