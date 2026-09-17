-- ====================================================================
-- 06_知识库入参补reportNo.sql —— 给知识库 input_param 补 reportNo
-- （自动生成，dry-run 产出，**未执行**）
--
-- 背景：2026-09-17 的入参迁移只给 agent_rule.request_params 补了 reportNo（Batch B），
--       漏了 knowledge_base_params.input_param —— 它就是**知识库详情页那个参数/测试集列表**。
--       结果：页面点进去看不到 reportNo，而 SQL 已要求 :reportNo 严格条件。
--
-- 规则：input_param 含 entName 但缺 reportNo → 在数组最前面插入 reportNo 条目。
--       与交付包 DML 使用**同一个函数**（KbInputParamFixer.ensureReportNo），保证两边一致。
--
-- ⚠️ 定界符写法：值必须紧贴 $mig$，换行只能在定界符之外。
-- ⚠️ 回滚：05_回滚_还原四列.sql 已覆盖 input_param（取自 bak_20260916_kb_params）。
-- ====================================================================

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"cdedd781-d8ef-4fce-bb3b-8f1cfd67f25a"},{"defaultValue":"","name":"entName","id":"a1b2c3d4-0003-4a03-9b03-000000000003"}]$mig$
WHERE paramno = 'IntelligentStrategyEngine';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"8a7e8d31-782d-46a5-b312-385006300952"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-jinglirun';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"c5a61180-1afd-4607-a0af-2d46d36c3fcc"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-nashuishouru';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"4bd9f222-c099-48a1-b011-0d1606ac8aeb"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-shishouziben';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"8768eb71-67ce-4b87-97a4-1b1e3539573f"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-xslljll';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"45edd0ce-c513-4409-803e-297ce6832c3b"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-yingyeshouru';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"aff06e19-e2ab-461c-8833-c0344d2f9d9d"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-yszk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"36d2644e-2a69-4a6c-8f66-e54845f785fe"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-zcfzlfx';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"6c7ff11b-e687-4dd0-872e-d0aea675fa0f"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-zuixinqici';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"95666579-3833-4452-ade0-52dce698caad"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-zuixinqicibingbiao';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"fe4aa34d-0002-4292-96b7-c525b8f304d0"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-zuixinqicishenji';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"345b9be5-4df6-41c3-9d05-18e43796519b"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'caiwu-zyfzkm';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"834c79fd-b77d-41c1-b6d9-a3726d5520e3"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'dxjclsqk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"963047a1-b05b-42a3-aa87-e2193280aa91"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"}]$mig$
WHERE paramno = 'dyawuqingkuang';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"966b6acd-e403-4e9c-a21e-fbe5b2d2efc2"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'fdckflcphkjh';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"e09dd23b-27cc-4606-aa43-0fc26474166f"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'gdcphkjh';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"0a78903b-67b4-4ebb-b185-290c932430be"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'gygdczbkjd-AI';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"973382af-ed9e-47f0-b0b1-4a9f32a2d2be"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'jkrsjfljyq';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"0641d965-d483-4611-9b0d-dc18566dd1e5"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-bbzsx';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"6d89df68-49d4-4a39-a0d6-a867cb82cec5"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-chzztsyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"10f4f7fb-96f4-4c38-b98a-f6d1e4f8b9b4"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-czxzql';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"e5752e4c-cf41-4a64-9945-d19cf844fc70"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"泰州公司","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-dfgzyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"43edc484-b73e-4ab4-8bb1-46fa52039d50"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'jyk-dfsryc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"782e25cc-3b80-4535-b356-28f0d694b7bd"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"泰州公司","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-dwdbjedqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"69049be9-62a5-4690-a971-fe85f7a93552"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-dywdcdy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"cb0dfd6e-14e3-41c9-bd3f-ddd26ede6406"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"张三","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-fyjljglvjkgr';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"f346d97f-5e0a-4cff-be01-f4c1139794c2"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"泰州公司","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-fyjljglvjkqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"de1daecc-5577-4c36-a2a7-08081e3bef9f"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"张三","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-fyzwmsgr';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"b9d2bd6c-ff49-49b4-a0ea-515ece400643"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"泰州公司","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-fyzwmsqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"58464034-29ee-4dcc-b407-5528eb063af2"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-gdjkwgh';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"6603859a-e69f-418c-9ce9-5a59736513f0"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-jlryc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"1b5a664c-3f97-48e1-9632-810da91c9808"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'jyk-jsyjybpp';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"d51767ed-e846-471e-8e18-eb00ccf8a621"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'jyk-jydxyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"abb817bc-f32e-4ae2-ad3d-ecdf0386c723"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"泰州公司","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-ldyebhqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"55a19c76-1b04-4394-91d7-cd4bdf9b9123"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-nashuixiaoshouyichang';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"0667edaf-b09b-42f8-b4ed-3832d63bf409"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-qzhgfxgzd';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"f6dfc097-a640-4cf8-9921-e8fd7c11e420"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-rzgdkz';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"9f1baf79-473c-4842-84ef-076ac604c832"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"张三","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-skrxlfgr';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"c29dcbab-5069-4a6c-b479-945fde45c105"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-sszbyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"f2b6ae8d-9bd1-4f03-985f-8b2c87b519fc"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-stzfdxyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"e22a8fce-a708-4b42-a234-c81647bf29fa"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'jyk-wysryc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"17a91f3f-ab78-4581-bd91-188c9e75810a"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-ysxiajiang';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"0353480d-7b0e-4628-8e87-60f17fed08f4"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-yszjhlwbrz';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"00c1843d-d670-42a6-a3d4-2b09b9b670c3"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-yszk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"750f9ffa-8238-40ae-a66b-119bb9bc6614"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-yszkzsyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"fc547a02-468a-4327-b621-945d6c192306"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-yszkzztsyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"972996cd-5dcf-4a3c-a2e6-849156280d71"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"泰州公司","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-yzrzgyfsqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"eb805c62-999d-4a3a-937c-746b43c68296"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-zffzlpldg';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"9f55ba55-86c7-4649-b79e-690c0c6c9bfa"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'jyk-zjysytyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"d7ec6f24-0f7c-4e7a-9dbe-f86e80451c58"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-zuyichangqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"73ab925d-d3b5-4c20-ba7b-d85b28b92e66"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"张三","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-zxcxbzyxqgr';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"625ef586-efce-475d-87f4-78ecd66057e0"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"泰州公司","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-zxcxbzyxqqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"00590060-3e45-4f85-a54a-f6e085902ff2"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"张三","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-zxcxycgr_copy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"38625a60-fd46-4aa2-b9d6-c20e16ff4fd4"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"张三","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-zxycgr';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"aa197f0a-fd56-4398-9458-e9d43ce1a7d3"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"},{"defaultValue":"泰州公司","name":"guarantorName","id":"5d0365b8-7abc-6fda-8b84-c6e3bad2248c"}]$mig$
WHERE paramno = 'jyk-zxycqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"b5ff126b-2fb6-4890-81e4-c9b15873ecd3"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'kehujigudonggk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"d7ebf2cf-416c-474b-8b06-462c7eebbe36"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'pfglyqlsqk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"9b8d0c9a-aee8-41d3-b25b-8335b25b08db"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'qiyesxyxqk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"2a65def2-2568-4695-acc9-1b2fd1ec2205"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'qiyezhuyaoywchanpin';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"5557806b-9d14-4231-bc71-605ece4d9eb9"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'rcdhjcbgjsfx';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"f5f69b19-f358-49de-8cff-801dada22979"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'scdhjcyj';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"3b0501bf-0fc5-4119-9e6d-e2def0c2ab10"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'skrsyr_copy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"af5bd6a5-b707-4f41-9ace-9751c253e7f0"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'syrskrfx-AI';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"d9c19d7d-ca3a-4d24-9b39-9e28a228f500"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'tddkjcqk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"fed099aa-f301-4d32-b30e-cbc18252fb76"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'whjsjydsqk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"63d72a21-7c00-494d-aacf-6b408fee952c"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'whjszhyzcqk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"3416ce4b-ae49-4e56-8a5e-da29df85fd24"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'whywdfk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"b55e15e1-3a41-4426-9e3b-d752fd27b45b"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'xcdkqk';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"d9182d83-2760-4e51-9fdc-3f1c82cc205f"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'xmdkytzs';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"9d5f3cca-6beb-493b-a0f8-7b14552ac4de"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'yjrwjyjxh';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"9871c5a5-b401-4142-b3db-823cf9cd7562"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'ysjgz-AI';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"493dc5e3-e47b-45b1-b2d3-18d39c5b2d17"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'yszjhlyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"d2e7c818-f26d-4c47-857c-782ab411de5f"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'zdfmyq-Ai';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"13bcd3d7-1d30-473f-8803-cbe79350da3d"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"459ec6a6-439f-ef41-d605-3e9b98d66c74"}]$mig$
WHERE paramno = 'zjycyspyjyj';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"cbd0cb10-52a1-4e61-90e8-4a2e2a6d75ac"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'zjysytyc';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"fce2c687-cb12-49a1-b53d-f0d9f3acf150"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"},{"defaultValue":"张三","name":"guarantorName","id":"bdf5209e-fb40-34dd-41df-0a7168524352"}]$mig$
WHERE paramno = 'zwqkmsgr';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"b6f81dbe-34b0-49c5-8b92-43ffd1a7b996"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"},{"defaultValue":"泰州公司","name":"guarantorName","id":"bdf5209e-fb40-34dd-41df-0a7168524352"}]$mig$
WHERE paramno = 'zwqkmsqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"8dfccebc-61b1-4e2d-b995-801e658e98bf"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"},{"defaultValue":"张三","name":"guarantorName","id":"bdf5209e-fb40-34dd-41df-0a7168524352"}]$mig$
WHERE paramno = 'zxcxcsgr';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"eb93188c-1db8-4268-82b9-dbb2fd6c0fa6"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"},{"defaultValue":"张三","name":"guarantorName","id":"bdf5209e-fb40-34dd-41df-0a7168524352"}]$mig$
WHERE paramno = 'zxcxsjmsgr';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"97c672f1-dec1-498c-ac80-b1faab13f525"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"},{"defaultValue":"泰州公司","name":"guarantorName","id":"bdf5209e-fb40-34dd-41df-0a7168524352"}]$mig$
WHERE paramno = 'zxcxsjmsqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"c9c485ca-1cef-4d83-9d42-f6b9fc8bbfd5"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"},{"defaultValue":"张三","name":"guarantorName","id":"bdf5209e-fb40-34dd-41df-0a7168524352"}]$mig$
WHERE paramno = 'zxqkmsgr';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"cc67023f-ac16-415f-a1ea-963cb4d62948"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"8bbcde52-f3b2-fe56-c723-b1c4477c70d9"},{"defaultValue":"泰州公司","name":"guarantorName","id":"bdf5209e-fb40-34dd-41df-0a7168524352"}]$mig$
WHERE paramno = 'zxqkmsqy';

UPDATE knowledge_base_params SET input_param = $mig$[{"defaultValue":"RPT-202603-001","name":"reportNo","id":"be3c8d26-37a0-4a0b-b8e9-051c8d719457"},{"defaultValue":"苏州XX精密机械制造有限公司","name":"entName","id":"911ee9f3-7d2b-4fd4-7fe3-f70af29ed03e"}]$mig$
WHERE paramno = 'zygdbg-AI';

