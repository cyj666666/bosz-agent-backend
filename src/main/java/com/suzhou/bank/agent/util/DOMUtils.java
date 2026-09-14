package com.suzhou.bank.agent.util;

import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.exception.ExceptionUtils;
import org.apache.commons.lang3.StringUtils;
import org.htmlcleaner.*;
import org.htmlcleaner.conditional.ITagNodeCondition;
import org.htmlcleaner.conditional.TagNodeAttExistsCondition;
import org.springframework.util.Assert;

import java.io.*;
import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * DOM操作工具类
 * @author: csxi
 * @date: 上午9:51 2021/2/23
 */
@Slf4j
public class DOMUtils {

    /* 返回祖先节点中最近的tagName节点 */
    public static TagNode parent(TagNode curNode, String tagName) {
        if (curNode == null) return null;
        TagNode parent = curNode.getParent();
        while(parent != null) {
            if (tagName.equals(parent.getName())) return parent;
            parent = parent.getParent();
        }
        return null;
    }

    /* 返回最近的上层节点 */
    public static TagNode parent(TagNode curNode) {
        if (curNode == null) return null;
        TagNode parent = curNode.getParent();
        if (parent != null) {
            return parent;
        }
        return null;
    }


    /* 深度复制 */
    public static TagNode deepCopy(TagNode node) {
        TagNode copy = node.makeCopy();
        if (node.hasChildren()) {
            List<TagNode> childTagList = node.getChildTagList();
            if (childTagList.size() == 0) {
                // 存在ContentNode
                copy.addChildren(node.getAllChildren());
            }
            List<TagNode> childrenCopy = childTagList.stream().map(tagNode -> deepCopy(tagNode)).collect(Collectors.toList());
            copy.addChildren(childrenCopy);
        }
        return copy;
    }

    /* 查找node下的占位节点 */
    public static TagNode findPlaceholderNode(TagNode node) {
        return node.findElementHavingAttribute("data-mce-annotation", true);
    }

    public static List<? extends TagNode> findPlaceHolderNodes(TagNode node) {
        ITagNodeCondition condition = new TagNodeAttExistsCondition("data-mce-annotation");
        return node.getElementList(condition, true);
    }

    /* 设置node节点下占位节点的值 */
    public static void setPlaceholderValue(TagNode node, String value) {
        TagNode placeholder = findPlaceholderNode(node);
        if (placeholder == null) return;
        placeholder.removeAllChildren();
        placeholder.addChild(new ContentNode(value));
    }

    /* 获取节点属性值 */
    public static String attr(TagNode node, String name) {
        return node != null? node.getAttributeByName(name): null;
    }

    /* 设置节点属性值 */
    public static void attr(TagNode node, String name, String value) {
        if (node == null) return;

        if (node.hasAttribute(name)) node.removeAttribute(name); // 若属性存在，先删除
        node.addAttribute(name, value);
    }

    /**
     * 增加可批注的节点标记
     */
    public static  void addCommentsFlag(TagNode node, String value){
        String className="";
        if (node.hasAttribute("class")) {
            className = node.getAttributeByName("class");
        }
        DOMUtils.attr(node,"class",className+" afrs-comments");
        DOMUtils.attr(node,"data-comments-serialNo",value);
    }

    /**
     * 删除节点上的data-属性
     * @param node
     */
    public static void removeDataAttr(TagNode node) {
        Map<String, String> attributes = node.getAttributes();
        attributes.forEach((k, v) -> {
            if (k.startsWith("data-")) {
                node.removeAttribute(k);
            }
        });
        //node.removeAttribute("contenteditable");
    }

    /**
     * 获取节点中的内容,及body中子节点,不存在body时返回自身
     */
    public static List getContent(TagNode node) {
        if (node == null) return Collections.EMPTY_LIST;
        TagNode body = node.findElementByName("body", true);
        return body == null? Arrays.asList(node): body.getAllChildren();
    }

    /**
     * 组合所有节点
     * @param nodes
     * @return
     */
    public static TagNode concatAll(List<TagNode> nodes) {
        TagNode html = new TagNode("html");
        TagNode head = new TagNode("head");
        // 全局样式
//        TagNode style = new TagNode("style");
//        style.addAttribute("type", "text/css");
//        style.addChild(new ContentNode("body { word-break: break-all; }"));
//        head.addChild(style);
        html.addChild(head);

        TagNode body = new TagNode("body");
        if (nodes != null) {
            for(TagNode node: nodes) {
                TagNode div = new TagNode("div");
                TagNode oldBody = node.findElementByName("body", false);
                if (oldBody == null) oldBody = node;
                String id = oldBody.getAttributeByName("id");
                div.addAttribute("id", id==null?"":id);
                String titleFlag = oldBody.getAttributeByName("titleFlag");
                if (StringUtils.isNotEmpty(titleFlag)) {
                    div.addAttribute("titleFlag", titleFlag);
                }
                div.addChild(getContent(node));
                body.addChildren(Arrays.asList(div));
            }
        }

        html.addChild(body);
        return html;
    }

    public static TagNode errorNode() {
        return errorNode("解析错误");
    }
    /**
     * 返回错误节点
     * @return
     */
    public static TagNode errorNode(String msg) {
        TagNode errorNode = new TagNode("span");
        errorNode.addChild(new ContentNode("【" + msg + "】"));
        errorNode.addAttribute("style", "color: red");
        return errorNode;
    }

    /**
     * 返回空行
     * @return
     */
    public static TagNode emptyLine() {
        return new TagNode("br");
    }

    /**
     * 将节点简单序列化
     * @param convertedNode
     * @return
     */
    public static String toString(TagNode convertedNode) {
//        checkLoop(convertedNode);
        try {
            CleanerProperties cleanerProperties = new CleanerProperties();
            cleanerProperties.setOmitXmlDeclaration(true);
            HtmlSerializer htmlSerializer = new SimpleHtmlSerializer(cleanerProperties,false);
            String content = htmlSerializer.getAsString(convertedNode);
//            return new String(content.getBytes(),"UTF-8").replace(" ", "&nbsp;");
            return new String(content.getBytes(),"UTF-8");
        } catch (UnsupportedEncodingException e) {
            log.error("解析数据异常{}", ExceptionUtils.getStackTrace(e));
            return null;
        }
    }

    /**
     * 检测节点是够形成环
     * @param node
     */
    public static void checkLoop(TagNode node) {
        checkLoop(node, new Stack<>());
    }
    private static void checkLoop(TagNode node, Stack<TagNode> stack) {
        Assert.isTrue(!stack.contains(node), "形成环：" + stack);
        // 检测node的子节点
        List<TagNode> childTagList = node.getChildTagList();
        if (childTagList != null) {
            stack.push(node); // 添加当前节点
            for (TagNode child: childTagList) {
                checkLoop(child, stack);
            }
            // 去除当前节点
            stack.pop();
        }
    }


    /**
     * 获得指定文件的byte数组
     *
     * @param filePath 文件绝对路径
     * @return
     */
    public static byte[] file2Byte(String filePath) {
        ByteArrayOutputStream bos = null;
        BufferedInputStream in = null;
        try {
            File file = new File(filePath);
            if (!file.exists()) {
                throw new FileNotFoundException("file not exists");
            }
            bos = new ByteArrayOutputStream((int) file.length());
            in = new BufferedInputStream(new FileInputStream(file));
            int buf_size = 1024;
            byte[] buffer = new byte[buf_size];
            int len = 0;
            while (-1 != (len = in.read(buffer, 0, buf_size))) {
                bos.write(buffer, 0, len);
            }
            return bos.toByteArray();
        } catch (Exception e) {
            System.out.println(e.getMessage());
            e.printStackTrace();
            return null;
        } finally {
            try {
                if (in != null) {
                    in.close();
                }
                if (bos != null) {
                    bos.close();
                }
            } catch (Exception e) {
                System.out.println(e.getMessage());
                e.printStackTrace();
            }
        }
    }

    /**
     * 根据byte数组，生成文件
     *
     * @param bfile    文件数组
     * @param filePath 文件存放路径
     * @param fileName 文件名称
     */
    public static void byte2File(byte[] bfile, String filePath, String fileName) {
        BufferedOutputStream bos = null;
        FileOutputStream fos = null;
        File file = null;
        try {
            File dir = new File(filePath);
            if (!dir.exists() && !dir.isDirectory()) {//判断文件目录是否存在
                dir.mkdirs();
            }
            file = new File(filePath + fileName);
            fos = new FileOutputStream(file);
            bos = new BufferedOutputStream(fos);
            bos.write(bfile);
        } catch (Exception e) {
            System.out.println(e.getMessage());
            e.printStackTrace();
        } finally {
            try {
                if (bos != null) {
                    bos.close();
                }
                if (fos != null) {
                    fos.close();
                }
            } catch (Exception e) {
                System.out.println(e.getMessage());
                e.printStackTrace();
            }
        }
    }

    public static String getAImgEndLabStr(String html) {
        StringBuffer sb = new StringBuffer();
        String tableComment = "<img ([^>]*)>";
        Pattern pattern = Pattern.compile(tableComment);
        Matcher matcher = pattern.matcher(html);
        while (matcher.find()) {
            String group = matcher.group();
            group = group.replace(">", "/>");
            group = group.replace("//>", "/>");
            matcher.appendReplacement(sb, group);
        }
        matcher.appendTail(sb);
        return sb.toString();
    }
}
