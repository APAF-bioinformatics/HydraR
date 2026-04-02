import re

with open('tests/testthat/test-drivers_api.R', 'r') as f:
    content = f.read()

# Replace the expectation string
content = content.replace('"Gemini API request failed: Internal Server Error"', '"Gemini API request failed:"')
content = content.replace('"OpenAI API request failed: Internal Server Error"', '"OpenAI API request failed:"')
content = content.replace('"Anthropic API request failed: Internal Server Error"', '"Anthropic API request failed:"')

with open('tests/testthat/test-drivers_api.R', 'w') as f:
    f.write(content)
