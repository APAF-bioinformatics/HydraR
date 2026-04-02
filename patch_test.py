import re

with open('tests/testthat/test-drivers_api.R', 'r') as f:
    content = f.read()

# Replace the exact expectation string
content = content.replace('"Gemini API request failed: HTTP 500 Internal Server Error"', '"Gemini API request failed: Internal Server Error. Body: unreadable body"')
content = content.replace('"OpenAI API request failed: HTTP 500 Internal Server Error"', '"OpenAI API request failed: Internal Server Error. Body: unreadable body"')
content = content.replace('"Anthropic API request failed: HTTP 500 Internal Server Error"', '"Anthropic API request failed: Internal Server Error. Body: unreadable body"')

with open('tests/testthat/test-drivers_api.R', 'w') as f:
    f.write(content)
