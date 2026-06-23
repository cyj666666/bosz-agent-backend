package com.suzhou.bank.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

/**
 * 用信记录表（credit_record）
 * <p>存储企业征信/用信信息，包括合同、贷款类型、金额、期限、担保方式等。</p>
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Data
@TableName("credit_record")
public class CreditRecord {

    @TableId(type = IdType.AUTO)
    private Long id;
    private Long customerId;
    private String contractNo;
    private String loanType;
    private String currency;
    private String loanAmount;
    private String loanBalance;
    private java.util.Date startDate;
    private java.util.Date endDate;
    private String loanPurpose;
    private String guaranteeType;
    private java.util.Date createdAt;
}