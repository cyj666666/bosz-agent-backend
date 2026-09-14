package com.suzhou.bank.agent.model.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ApplyPromptDTO {

    private String sceneName;

    private String prompt;

    private String largeModelCode;

    private String expectFormat;

}
