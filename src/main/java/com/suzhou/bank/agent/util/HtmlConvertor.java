package com.suzhou.bank.agent.util;

import com.alibaba.fastjson.JSONObject;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.collections4.CollectionUtils;
import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.apache.commons.lang3.tuple.Pair;
import org.htmlcleaner.BaseToken;
import org.htmlcleaner.ContentNode;
import org.htmlcleaner.HtmlCleaner;
import org.htmlcleaner.TagNode;
import com.suzhou.bank.agent.util.JSONTools;
import com.suzhou.bank.agent.core.BaseParam;
import com.suzhou.bank.agent.entity.IndexParamsEntity;
import com.suzhou.bank.agent.service.IIndexParamsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.util.Assert;

import java.util.*;
import java.util.stream.Collectors;

@Slf4j
@Component
public class HtmlConvertor {

    @Autowired
    private IIndexParamsService indexParamsService;


    public TagNode convert(TagNode tagNode, Map<String, Object> valueMap, List<IndexParamsEntity> paramsList) {
        // 获取所有需要转换的节点
        Set<TagNode> handledNode = new HashSet<>();
        List<? extends TagNode> allNodes = tagNode.getElementListHavingAttribute("data-param-no", true);
        if (!CollectionUtils.isEmpty(allNodes)) {
            allNodes.forEach(n -> {
                // 处理每一个节点
                try {
                    Map<String, String> attributes = n.getAttributes();
                    String expand = attributes.get("data-expand");
                    if (StringUtils.isEmpty(expand)) {
                        return;
                    }
                    if (expand.equals("row")) {
                        handleRowExpand(n, valueMap, paramsList, handledNode);
                    } else {
                        handleNoExpand(n, valueMap, paramsList);
                    }
                } catch (IllegalArgumentException e) {
                    DOMUtils.removeDataAttr(n);
                    log.error("解析模板出错", e);
                }
            });
        }
        return tagNode;
    }

    public TagNode convertV2(TagNode tagNode, Map<String, Object> valueMap, List<IndexParamsEntity> paramsList) {
        // 获取所有需要转换的节点
        Set<TagNode> handledNode = new HashSet<>();
        List<? extends TagNode> allNodes = tagNode.getElementListHavingAttribute("data-mce-annotation", true);
        if (!CollectionUtils.isEmpty(allNodes)) {
            allNodes.forEach(n -> {
                // 处理每一个节点
                try {
                    Map<String, String> attributes = n.getAttributes();
                    String expand = attributes.get("data-expand");
                    if (StringUtils.isEmpty(expand)) {
                        return;
                    }
                    if (expand.equals("row")) {
                        handleNewRowExpand(n, valueMap, paramsList, handledNode);
                    } else {
                        handleNewNoExpand(n, valueMap, paramsList);
                    }
                } catch (IllegalArgumentException e) {
                    DOMUtils.removeDataAttr(n);
                    log.error("解析模板出错", e);
                }
            });
        }
        return tagNode;
    }

    public Pair<List<String>, Map<String, String>> getInputField(String html) {
        List<String> inputFieldList = null;
        Map<String, String> attributes = null;
        try {
            HtmlCleaner htmlCleaner = new HtmlCleaner();
            TagNode tagNode = htmlCleaner.clean(html);
            inputFieldList = new ArrayList<>();
            attributes = new HashMap<>();
            TagNode[] tagNodes = tagNode.getElementsByName("th", true);
            List<? extends TagNode> allNodes = tagNode.getElementListHavingAttribute("data-mce-annotation", true);
            if (!CollectionUtils.isEmpty(allNodes)) {
                for (int i = 0; i < allNodes.size(); i++) {
                    try {
                        BaseToken baseToken = allNodes.get(i).getAllChildren().get(0);
                        if (Objects.isNull(baseToken) || StringUtils.isEmpty(baseToken.toString())) {
                            continue;
                        }
                        String tokenString = baseToken.toString();
                        String[] split = tokenString.substring(tokenString.indexOf("{"), tokenString.indexOf("}") + 2).replace("{{", "").replace("}}", "").split("\\|\\|");
                        if (split.length != 2) {
                            continue;
                        }
                        inputFieldList.add(split[0]);
                        attributes.put(split[0], tagNodes[i].getAllChildren().get(0).toString());
                    } catch (IllegalArgumentException e) {
                        DOMUtils.removeDataAttr(allNodes.get(i));
                        log.error("解析模板出错", e);
                    }
                }
            }
        } catch (Exception e) {
            log.error("解析html中指标和指标名称出错{}", ExceptionUtils.getStackTrace(e));
        }
        return Pair.of(inputFieldList, attributes);
    }

    private void handleNoExpand(TagNode
                                        curNode, Map<String, Object> valueMap, List<IndexParamsEntity> paramsList) {
        String objValue = "&nbsp;";
        String curParamNo = curNode.getAttributeByName("data-param-no");
        List<IndexParamsEntity> indexParamsEntityList = paramsList.stream().filter(p -> p.getParamNo().equals(curParamNo)).collect(Collectors.toList());
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            IndexParamsEntity param = indexParamsEntityList.get(0);
            if (Objects.nonNull(param)) {
                Object parentValue = Objects.isNull(valueMap.get(param.getParentParamNo())) ? valueMap.get(param.getOtherNo()) : valueMap.get(param.getParentParamNo());
                if (Objects.nonNull(parentValue) && parentValue instanceof List) {
                    JSONObject value = (JSONObject) ((ArrayList) parentValue).get(0);
                    if (Objects.nonNull(value)) {
                        objValue = String.valueOf(value.get(param.getParamID()));
                    }
                }
                if (Objects.nonNull(parentValue) && parentValue instanceof JSONObject) {
                    JSONObject value = (JSONObject) parentValue;
                    objValue = String.valueOf(Objects.isNull(value.get(param.getParamID())) ? value.get(param.getParamName()) : value.get(param.getParamID()));
                }
            }
        }
        if ("&nbsp;".equals(objValue)) {
            TagNode table = DOMUtils.parent(curNode, "table");
            if (Objects.nonNull(table)) {
                table.removeAllChildren();
            }
            return;
        }

        TagNode tagNodeP = new TagNode("span");
        tagNodeP.addAttribute("style", "width: 100%;font-size:".concat(";font-family: simsun"));
        tagNodeP.addChild(new ContentNode(objValue));
        replace(curNode, tagNodeP);
    }

    private void handleNewNoExpand(TagNode
                                           curNode, Map<String, Object> valueMap, List<IndexParamsEntity> paramsList) {
        String objValue = "&nbsp;";
        BaseToken baseToken = curNode.getAllChildren().get(0);
        if (Objects.isNull(baseToken)) {
            return;
        }
        String[] split = baseToken.toString().replace("{{", "").replace("}}", "").split("\\|\\|");
        if (split.length != 2) {
            return;
        }
        String curParamNo = split[1];
        List<IndexParamsEntity> indexParamsEntityList = paramsList.stream().filter(p -> p.getParamNo().equals(curParamNo)).collect(Collectors.toList());
        if (CollectionUtils.isNotEmpty(indexParamsEntityList)) {
            IndexParamsEntity param = indexParamsEntityList.get(0);
            if (Objects.nonNull(param)) {
                Object parentValue = Objects.isNull(valueMap.get(param.getParentParamNo())) ? valueMap.get(param.getOtherNo()) : valueMap.get(param.getParentParamNo());
                if (Objects.nonNull(parentValue) && parentValue instanceof List) {
                    JSONObject value = (JSONObject) ((ArrayList) parentValue).get(0);
                    if (Objects.nonNull(value)) {
                        objValue = String.valueOf(value.get(param.getParamID()));
                    }
                }
                if (Objects.nonNull(parentValue) && parentValue instanceof JSONObject) {
                    JSONObject value = (JSONObject) parentValue;
                    objValue = String.valueOf(Objects.isNull(value.get(param.getParamID())) ? value.get(param.getParamName()) : value.get(param.getParamID()));
                }
            }
        }
        if ("&nbsp;".equals(objValue)) {
            TagNode table = DOMUtils.parent(curNode, "table");
            if (Objects.nonNull(table)) {
                table.removeAllChildren();
            }
            return;
        }

        TagNode tagNodeP = new TagNode("span");
        tagNodeP.addAttribute("style", "width: 100%;font-size:".concat(";font-family: simsun"));
        tagNodeP.addChild(new ContentNode(objValue));
        replace(curNode, tagNodeP);
    }

    private <T extends BaseParam> void handleRowExpand(TagNode
                                                               curNode, Map<String, Object> valueMap, List<IndexParamsEntity> paramsList, Set<TagNode> handledNode) {
        // 若节点在context已处理节点中，则说明已被处理，直接结束
        if (handledNode.contains(curNode)) return;

        TagNode tr = DOMUtils.parent(curNode, "tr");
        Assert.notNull(tr, "行循环需在表格内");

        List<? extends TagNode> placeHolderNodes = DOMUtils.findPlaceHolderNodes(tr);
        handledNode.addAll(placeHolderNodes);

        TagNode tbody = DOMUtils.parent(tr, "tbody");

        // 自动表格数据打上标签
        TagNode table = DOMUtils.parent(tbody, "table");
        Map<String, String> attributes = table.getAttributes();
        String calssAttr = StringUtils.isEmpty(attributes.get("class")) ? "" : attributes.get("class");
        calssAttr = "input-table " + calssAttr;
        attributes.put("class", calssAttr);
        table.setAttributes(attributes);

        // 循环次数
        int size = 0;
        Object data = null;
        for (TagNode tagNode : placeHolderNodes) {
            String curParamNo = tagNode.getAttributeByName("data-param-no");
            List<IndexParamsEntity> indexParamsEntityList = paramsList.stream().filter(p -> p.getParamNo().equals(curParamNo)).collect(Collectors.toList());
            if (CollectionUtils.isEmpty(indexParamsEntityList)) {
                continue;
            }
            IndexParamsEntity param = indexParamsEntityList.get(0);
            if (Objects.isNull(param)) {
                continue;
            }
            data = Objects.isNull(valueMap.get(param.getParentParamNo())) ? valueMap.get(param.getOtherNo()) : valueMap.get(param.getParentParamNo());
            if (data instanceof List) {
                size = ((List<?>) data).size();
            }
            break;
        }

        // 列表无数据，显示一行空行
        if (size == 0) {
            table.removeAllChildren();
            return;
        }

        for (int i = 0; i < size; i++) {
            TagNode trCopy = tr.makeCopy();
            tbody.insertChildBefore(tr, trCopy);

            List<? extends TagNode> tdList = tr.getElementListByName("td", false);
            for (TagNode td : tdList) {
                TagNode tdCopy = DOMUtils.deepCopy(td);
                TagNode placeholderNode = DOMUtils.findPlaceholderNode(tdCopy);
                String curParamNo = placeholderNode.getAttributeByName("data-param-no");
                List<IndexParamsEntity> indexParamsEntityList = paramsList.stream().filter(p -> p.getParamNo().equals(curParamNo)).collect(Collectors.toList());
                if (CollectionUtils.isEmpty(indexParamsEntityList)) {
                    continue;
                }
                IndexParamsEntity param = indexParamsEntityList.get(0);

                // 自动表格td打上属性值标签
                Map<String, String> tdAttributes = tdCopy.getAttributes();
                tdAttributes.put("id-data", param == null ? "" : param.getParamID() == null ? "" : param.getParamID());
                tdCopy.setAttributes(tdAttributes);

                TagNode retNode = doHandle(param, placeholderNode, data, i);
                replace(placeholderNode, retNode);
                trCopy.addChild(tdCopy);
            }
        }
        tbody.removeChild(tr);
    }

    private <T extends BaseParam> void handleNewRowExpand(TagNode curNode, Map<String, Object> valueMap, List<IndexParamsEntity> paramsList, Set<TagNode> handledNode) {
        // 若节点在context已处理节点中，则说明已被处理，直接结束
        if (handledNode.contains(curNode)) return;

        TagNode tr = DOMUtils.parent(curNode, "tr");
        Assert.notNull(tr, "行循环需在表格内");

        List<? extends TagNode> placeHolderNodes = DOMUtils.findPlaceHolderNodes(tr);
        handledNode.addAll(placeHolderNodes);

        TagNode tbody = DOMUtils.parent(tr, "tbody");

        // 自动表格数据打上标签
        TagNode table = DOMUtils.parent(tbody, "table");
        Map<String, String> attributes = table.getAttributes();
        String calssAttr = StringUtils.isEmpty(attributes.get("class")) ? "" : attributes.get("class");
        calssAttr = "input-table " + calssAttr;
        attributes.put("class", calssAttr);
        table.setAttributes(attributes);

        // 循环次数
        int size = 0;
        Object data = null;
        for (TagNode tagNode : placeHolderNodes) {
            BaseToken baseToken = tagNode.getAllChildren().get(0);
            if (Objects.isNull(baseToken) || StringUtils.isEmpty(baseToken.toString())) {
                continue;
            }
            // 取{{}}中的paramNo
            String tokenString = baseToken.toString();
            String[] split = tokenString.substring(tokenString.indexOf("{"), tokenString.indexOf("}") + 2).replace("{{", "").replace("}}", "").split("\\|\\|");
            if (split.length != 2) {
                continue;
            }
            String curParamNo = split[1];
            List<IndexParamsEntity> indexParamsEntityList = paramsList.stream().filter(p -> p.getParamNo().equals(curParamNo)).collect(Collectors.toList());
            if (CollectionUtils.isEmpty(indexParamsEntityList)) {
                continue;
            }
            IndexParamsEntity param = indexParamsEntityList.get(0);
            if (Objects.isNull(param)) {
                continue;
            }
            data = Objects.isNull(valueMap.get(param.getParentParamNo())) ? valueMap.get(param.getOtherNo()) : valueMap.get(param.getParentParamNo());
            if (data instanceof List) {
                size = ((List<?>) data).size();
            }
            break;
        }

        // 列表无数据，显示一行空行
        if (size == 0) {
            table.removeAllChildren();
            return;
        }

        for (int i = 0; i < size; i++) {
            TagNode trCopy = tr.makeCopy();
            tbody.insertChildBefore(tr, trCopy);

            List<? extends TagNode> tdList = tr.getElementListByName("td", false);
            for (TagNode td : tdList) {
                TagNode tdCopy = DOMUtils.deepCopy(td);
                TagNode placeholderNode = DOMUtils.findPlaceholderNode(tdCopy);

                BaseToken baseToken = placeholderNode.getAllChildren().get(0);
                if (Objects.isNull(baseToken) || StringUtils.isEmpty(baseToken.toString())) {
                    continue;
                }
                String tokenString = baseToken.toString();
                String[] split = tokenString.substring(tokenString.indexOf("{"), tokenString.indexOf("}") + 2).replace("{{", "").replace("}}", "").split("\\|\\|");
                if (split.length != 2) {
                    continue;
                }
                String curParamNo = split[1];
                List<IndexParamsEntity> indexParamsEntityList = paramsList.stream().filter(p -> p.getParamNo().equals(curParamNo)).collect(Collectors.toList());
                if (CollectionUtils.isEmpty(indexParamsEntityList)) {
                    continue;
                }
                IndexParamsEntity param = indexParamsEntityList.get(0);
                if (StringUtils.isNotEmpty(split[0])) {
                    param.setParamName(split[0]);
                }
                // 自动表格td打上属性值标签
                Map<String, String> tdAttributes = tdCopy.getAttributes();
                tdAttributes.put("id-data", param == null ? "" : param.getParamID() == null ? "" : param.getParamID());
                tdCopy.setAttributes(tdAttributes);

                TagNode retNode = doHandle(param, placeholderNode, data, i);
                replace(placeholderNode, retNode);
                trCopy.addChild(tdCopy);
            }
        }
        tbody.removeChild(tr);
    }

    private static void replace(TagNode node, TagNode contentNode) {
        if (contentNode != null) {
            if ("table".equals(node.getName()) || "img".equals(node.getName())) {
                TagNode parent = node.getParent();
                parent.insertChildAfter(node, contentNode);
                parent.removeChild(node);
            } else {
                TagNode n = removeUnlessStyleNode(node);
                n.addChild(contentNode);
            }
        }
    }

    private static TagNode removeUnlessStyleNode(TagNode node) {
        List<TagNode> children = node.getChildTagList();
        if (CollectionUtils.isNotEmpty(children)) {
            // 首个子节点
            TagNode firstChild = children.get(0);
            node.removeAllChildren();
            String tagName = firstChild.getName();
            if ("em".equals(tagName) || "strong".equals(tagName) || "span".equals(tagName)) {
                node.addChild(firstChild);
                return removeUnlessStyleNode(firstChild);
            }
        } else if (node.hasChildren()) {
            // 清除内容节点
            node.removeAllChildren();
        }
        return node;
    }

    private TagNode doHandle(IndexParamsEntity param, TagNode curNode, Object data, Integer index) {
        Object value = "";
        if (data instanceof JSONObject) {
            JSONObject obj = (JSONObject) data;
            value = obj.size() > 0 ? (!StringUtils.isEmpty(obj.getString(param.getParamID())) ? JSONTools.getString(obj, param.getParamID()) : "") : "";
        }
        if (data instanceof List) {
            List tmp = (List) data;
            JSONObject obj = tmp.size() > 0 ? (JSONObject) tmp.get(index) : new JSONObject();
            value = obj.size() > 0 ? (!StringUtils.isEmpty(obj.getString(param.getParamID())) ? JSONTools.getString(obj, param.getParamID()) : obj.getString(param.getParamName())) : "";
        }
        Object finalVal = value;

        String style = curNode.getAttributeByName("style");
        TagNode tagNode = new TagNode("span");
        if (StringUtils.isNotEmpty(style)) {
            tagNode.addAttribute("style", style);
        }
        tagNode.addChild(new ContentNode(finalVal == null ? "" : finalVal.toString()));
        return tagNode;
    }
}
