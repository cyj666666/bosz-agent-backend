package com.suzhou.bank.agent.util;

import com.alibaba.fastjson.JSON;
import com.alibaba.fastjson.JSONArray;
import com.alibaba.fastjson.JSONObject;
import com.alibaba.fastjson.parser.Feature;
import com.alibaba.fastjson.serializer.BeforeFilter;
import com.alibaba.fastjson.serializer.SerializerFeature;
import com.alibaba.fastjson.serializer.ValueFilter;
import cn.hutool.core.date.DateUtil;
import org.apache.commons.lang3.StringUtils;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Created by yangdengwu on 17-9-21.
 */
public class JSONTools {
	
	public static JSONObject createJSONObject() {
		return new JSONObject(true);
	}
	
	public static JSONObject parseObject(String text) {
		if (StringUtils.isBlank(text)) {
			return new JSONObject(true);
		}
		
		return JSON.parseObject(text, Feature.OrderedField);
	}
	
	public static JSONArray parseJsonArray(String text) {
		if (StringUtils.isBlank(text)) {
			return new JSONArray(0);
		}
		
		return JSON.parseArray(text);
	}
	
	public static void setSimilarValue(JSONObject jsonObj, String key, Object value){
		if (null != jsonObj){
			if(jsonObj.containsKey(key)){
				jsonObj.put(key, value);
				return;
			}
			Set<String> keys = jsonObj.keySet();
			for (String curKey : keys) {
				if (curKey.equalsIgnoreCase(key)) {
					jsonObj.put(curKey, value);
					return;
				}
			}
			jsonObj.put(key, value);
		}
	}
	
	public static void remove(JSONObject jsonObj,String...keys) {
		if (null != jsonObj) {
			Set<String> jsonKeys = jsonObj.keySet();
			Map<String, String> keysMap = new HashMap<>();
			for (String jsonKey : jsonKeys) {
				keysMap.put(jsonKey.toUpperCase(), jsonKey);
			}
			for (String key : keys) {
				if (keysMap.containsKey(key.toUpperCase())) {
					String jsonKey = keysMap.get(key.toUpperCase());
					jsonObj.remove(jsonKey);
				}
			}
		}
	}	

    public static Object getValue(JSONObject jsonObj, String key) {
    	if (jsonObj == null || jsonObj.isEmpty() || StringUtils.isBlank(key)) {
    		return null;
    	}
    	
    	if(jsonObj.containsKey(key)){
    		return jsonObj.get(key);
    	}
        Set<String> keys = jsonObj.keySet();
        for (String curKey : keys) {
            if (curKey.equalsIgnoreCase(key)) {
                return jsonObj.get(curKey);
            }
        }

        return null;
    }
    
    public static boolean containsKey(JSONObject jsonObj,String key) {
    	Set<String> keys = jsonObj.keySet();
    	for (String curKey : keys) {
    		if (curKey.equalsIgnoreCase(key)) return true;
    	}
    	    	
    	return false;
    }
    
    public static String getString(JSONObject jsonObj,String key) {
    	Object value = getValue(jsonObj, key);
    	if (value == null) {
    		return null;
    	}
    	
    	return value.toString();
    }
    
    public static String getStringValue(JSONObject jsonObj,String fieldName){
		if (!jsonObj.containsKey(fieldName)) {
			return null;
		}
			
		Object obj = jsonObj.get(fieldName);
		StringBuffer builder = new StringBuffer();
		if (obj != null && obj instanceof JSONObject) {
			JSONObject jsonObjTemp = (JSONObject)obj;
			Set<String> keys = jsonObjTemp.keySet();
			for (String key : keys) {
				Object value = jsonObjTemp.get(key);
				if (value != null) {
					builder.append(key).append("=").append(value).append(";");
				}
			}
			if (builder.length() > 0) {
				builder.deleteCharAt(builder.length() - 1);
			}
		} else {
			builder.append(obj == null ? null : obj.toString());
		}
		
		return builder.toString();
    }
    
    public static String getString(JSONObject jsonObj,String key,String defaultValue) {
    	Object value = getValue(jsonObj, key);
    	if (value == null) {
    		value = defaultValue;
    	}
    	
    	return value.toString();
    }
    
    public static Integer getInt(JSONObject jsonObj,String key) {
    	Object value = getValue(jsonObj, key);
    	if (value == null) {
    		return null;
    	}
    	
    	return parseInteger(key,value);
    }
    
    public static Double getDouble(JSONObject jsonObj,String key) {
    	Object value = getValue(jsonObj, key);
    	if (value == null) {
    		return null;
    	}
    	
    	return parseDouble(value);
    }
    
    public static Double getDouble(JSONObject jsonObj,String key,Double defaultValue) {
    	Object value = getValue(jsonObj, key);
    	if (value == null) {
    		return defaultValue;
    	}
    	
    	return parseDouble(value);
    } 
    
    public static Integer getInt(JSONObject jsonObj,String key,Integer defaultValue) {
    	Object value = getValue(jsonObj, key);
    	if (value == null) {
    		return defaultValue;
    	}
    	
    	return parseInteger(key,value);
    }
    
    public static JSONObject getJSONObject(JSONObject jsonObject,String key) {
    	Object value = getValue(jsonObject, key);
    	if (value == null) {
    		return new JSONObject();
    	}
    	
    	if (!(value instanceof JSONObject)) {
    		throw new RuntimeException("Key:"+key+"属性值不是JSON对象,原始值为:"+value);
    	}
    	return (JSONObject) value;
    }
    
    public static JSONArray getJSONArray(JSONObject jsonObject,String key) {
    	Object value = getValue(jsonObject, key);
    	if (value == null) {
    		return new JSONArray();
    	}
    	
    	if (!(value instanceof JSONArray)) {
    		throw new RuntimeException("Key:"+key+"属性值不是JSONArray,原始值为:"+value);
    	}
    	
    	return (JSONArray) value;
    }
    
    private static Integer parseInteger(String key,Object value) {
    	if (value instanceof String) {
    		String regex = "\\d+";
    		String s = (String) value;
    		if (s.matches(regex)) {
    			return Integer.parseInt(s);
    		} else if ("null".equalsIgnoreCase(s)) {
    			return null;
    		}
    		throw new RuntimeException("无法将value:"+value+"转换成int型");
    	}
    	if (value == null) {
    		return null;
    	}
    	if (!(value instanceof Number)) {
    		throw new RuntimeException("无法将value:"+value+"转换成int型");
    	}
    	Number number = (Number)value;
    	
    	return number.intValue();
    }
    
    
    private static Double parseDouble(Object value) {
    	if (value instanceof String) {
    		String s = (String) value;
    		String regex = "\\d+(\\.\\d+)?";
    		if (s.matches(regex)) {
    			return Double.parseDouble(s);
    		} else if ("null".equalsIgnoreCase(s)) {
    			return null;
    		}
    		throw new RuntimeException("无法将value:"+value+"转换成Double型");
    	} else {
    		if (value == null) {
    			return null;
    		}
    		if (!(value instanceof Number)) {
    			throw new RuntimeException("无法将value:"+value+"转换成Double型");
    		}
    		Number number = (Number)value;
        	
        	return number.doubleValue(); 
    	}
    }
    

    
    private static Object intercept(Object value,int length) {
    	if (value == null || !(value instanceof String)) {
    		return value;
    	}
    	String sourceValue = (String) value;
    	int sourceLength = sourceValue.length();
    	if (sourceLength <= length) {
    		return sourceValue;
    	}
    	
    	return sourceValue.substring(0, length);
    }
    

    

   
    
    public static JSONArray replaceValue2JSONArray(JSONArray array,String inputParam,String paramValue) {
    	JSONArray jsonArray = new JSONArray();
    	if (array == null || array.isEmpty()) {
    		return jsonArray;
    	}
    	
    	for (int i = 0; i < array.size(); i++) {
    		JSONObject jsonObject2 = array.getJSONObject(i);

    		Set<String> keys = jsonObject2.keySet();
    	    for (String curKey : keys) {
    	        if (curKey.equalsIgnoreCase(inputParam)) {
    	        	jsonObject2.put(curKey, paramValue) ;
    	        }
    	    }
    	    
    	    jsonArray.add(jsonObject2);
    	
		}
    	
    	return jsonArray;
    }
    
    
    public static String toJSONString(JSONObject jsonObj) {
    	return JSONObject.toJSONString(jsonObj
    			,VALUE_FILTER
    			,SerializerFeature.WriteNullListAsEmpty
    			,SerializerFeature.WriteNullStringAsEmpty
    			);
    }
    
    
    private static final ValueFilter VALUE_FILTER = new ValueFilter() {
		@Override
		public Object process(Object object, String name, Object value) {
			if (value == null) {
				return "";
			}
			
			return value;
		}
	};

	public static final BeforeFilter NONE_EDSINPUTTIME_FILTER = new BeforeFilter() {
		@Override
		public void writeBefore(Object o) {
			JSONObject jsonObject = (JSONObject) o;
			jsonObject.put("edsinputtime", DateUtil.now());
		}
	};
	
	/**
	 * JSONObject替换key
	 * 
	 * @param jsonObj
	 * @param keyMap
	 *            key为old,value为new
	 * @return
	 */
	public static JSONObject changeJsonObjKey(JSONObject jsonObj, Map<String, String> keyMap) {
		JSONObject resJson = new JSONObject(true);
		Set<String> keySet = jsonObj.keySet();
		for (String key : keySet) {
			String resKey = keyMap.get(key) == null ? key : keyMap.get(key);
			try {
				JSONObject jsonobj1 = jsonObj.getJSONObject(key);
				resJson.put(resKey, changeJsonObjKey(jsonobj1, keyMap));
			} catch (Exception e) {
				try {
					JSONArray jsonArr = jsonObj.getJSONArray(key);
					resJson.put(resKey, changeJsonArrKey(jsonArr, keyMap));
				} catch (Exception x) {
					resJson.put(resKey, jsonObj.get(key));
				}
			}
		}
		return resJson;
	}
	
	/**
	 * JSONArray替换key
	 * 
	 * @param jsonArr
	 * @param keyMap
	 *            key为old,value为new
	 * @return
	 */
	public static JSONArray changeJsonArrKey(JSONArray jsonArr, Map<String, String> keyMap) {
		JSONArray resJson = new JSONArray();
		for (int i = 0; i < jsonArr.size(); i++) {
			JSONObject jsonObj = jsonArr.getJSONObject(i);
			resJson.add(changeJsonObjKey(jsonObj, keyMap));
		}
		return resJson;
	}
	
	/**
	 * 根据检索类型Key的List获取指定JSONArray
	 * 
	 * @param jsonArr
	 * @param keyList
	 * @return
	 */
	public static JSONArray getKeyJSONArray(JSONArray jsonArr, List<String> keyList) {
		JSONArray mdata = new JSONArray();
		if (jsonArr == null || jsonArr.size() == 0 || keyList == null || keyList.size() == 0) {
			return jsonArr;
		}
		for (int i = 0; i < jsonArr.size(); i++) {
			JSONObject mlistName = new JSONObject();
			for (int j = 0; j < keyList.size(); j++) {
				String listName = keyList.get(j);
				JSONArray mSerilnoDataArray = jsonArr.getJSONObject(i).getJSONArray(listName);
				mlistName.put(listName, mSerilnoDataArray);
			}
			mdata.add(mlistName);
		}
		return mdata;
	}

	public static int getPageNo(JSONObject object){
		int pageNo = 1;
		pageNo = getInt(object, "pageNo", 1);
		if (pageNo < 1){
			pageNo =1;
		}
		return pageNo;
	}

	public static int getPageIndex(JSONObject object){
		int pageIndex = 1;
		pageIndex = getInt(object, "pageIndex", 1);
		if (pageIndex < 1){
			pageIndex =1;
		}
		return pageIndex;
	}

	public static int getPageSize(JSONObject object){
		int pageSize = 1;
		pageSize = getInt(object, "pageSize", 10);
		if (pageSize < 1){
			pageSize =10;
		}
		if (pageSize > 200){
			pageSize = 200;
		}
		return pageSize;
	}
}
