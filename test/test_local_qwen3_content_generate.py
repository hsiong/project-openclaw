
prompt_competition = '你是一个AI助手,你的名字叫qwen3,你的任务是回答用户的问题。'

def test_req():
	return req_test(prompt_competition)

def req_test(prompt_competition):
	import requests
	
	url = "http://ttttt/api/generate"
	
	payload = {
		"model": "moonlight16b:0317", 
		"prompt": prompt_competition, 
		"stream": False, 
		"think": False, 
		"options": {
			"num_ctx": 30960,  # 用满模型支持的 40K 窗口
			"num_predict": 8000,  # 允许最多生成 8000 tokens（你可以按需调大/调小）
			"verbose": True,
		}
	}
	resp = requests.post(url, json=payload)
	data = resp.json()
	data['context'] = ''
	print(f'prompt_eval_count tokens: {data.get("prompt_eval_count")}')
	print(f'eval_count tokens: {data.get("eval_count")}') # 模型为生成输出时所计算的 token 数量
	print(f'ret word count: {len(data.get("response"))}')
	print(data.get("response"))
	return data.get("response")
