package com.suzhou.bank.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.suzhou.bank.entity.Report;
import org.apache.ibatis.annotations.Mapper;

/**
 * 报告主表 Mapper
 *
 * @author cyj666666
 * @since 1.0.0
 */
@Mapper
public interface ReportMapper extends BaseMapper<Report> {
}
