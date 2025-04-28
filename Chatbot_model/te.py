from transformers import AutoTokenizer, AutoModelForCausalLM, pipeline
import torch
import re

# Model setup
model_name = "deepseek-ai/DeepSeek-R1-Distill-Qwen-1.5B"

tokenizer = AutoTokenizer.from_pretrained(model_name, trust_remote_code=True)
model = AutoModelForCausalLM.from_pretrained(
    model_name, 
    torch_dtype=torch.float16,
    device_map="auto",
    trust_remote_code=True
)

# Create generation pipeline
generator = pipeline(
    "text-generation",
    model=model,
    tokenizer=tokenizer,
    max_length=512,
    temperature=0.7,
    top_p=0.9,
    repetition_penalty=1.1
)

# Prompts

# Prompts
system_prompt = """
You are a compassionate and understanding AI companion. Respond with warmth and empathy, but keep your replies concise — around 2 lines. Focus on validating emotions, offering gentle encouragement, and making people feel heard and supported. Avoid long explanations; simplicity and kindness matter most.
"""


user_message = "I've been feeling really alone lately. It's been a tough week."

# Format input
final_prompt = (
    "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n"
    f"{system_prompt}\n"
    "<|start_header_id|>user<|end_header_id|>\n"
    f"{user_message}\n"
    "<|start_header_id|>assistant<|end_header_id|>\n"
)

# Clean function
def clean_response(text):
    # Remove <think> tags
    text = re.sub(r'<think>.*?</think>', '', text, flags=re.DOTALL)
    text = text.replace('<think/>', '')
    
    # Remove common reasoning phrases
    patterns_to_remove = [
        r'Let me think about this\.?',
        r'I should respond with\.?',
        r'I understand that\.?',
        r'Let me provide\.?',
        r'I will\.?',
        r'I need to\.?',
        r'First, ',
        r'Therefore, ',
        r'Given this, ',
        r'Based on this, ',
        r'In conclusion, ',
    ]
    for pattern in patterns_to_remove:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE)
    
    # Remove sentences that start with analytic words
    sentences = text.split('.')
    cleaned_sentences = [
        s.strip() for s in sentences if not any(
            s.strip().lower().startswith(word) for word in [
                'considering', 'analyzing', 'thinking', 'reasoning'
            ]
        )
    ]
    text = '. '.join(cleaned_sentences).strip()
    
    # Final clean-up
    text = re.sub(r'\s+', ' ', text)  # collapse multiple spaces
    return text

# Generate response
response = generator(final_prompt, do_sample=True)[0]['generated_text']

# Extract the assistant's reply
assistant_reply = response.split("<|start_header_id|>assistant<|end_header_id|>")[-1].strip()

# Clean it
cleaned_reply = clean_response(assistant_reply)

# Output
print(cleaned_reply)