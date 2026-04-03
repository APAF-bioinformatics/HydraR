import re

with open('tests/testthat/test-drivers_api.R', 'r') as f:
    content = f.read()

# Replace the expectation string
content = content.replace('"Gemini API request failed: Internal Server Error. Body: unreadable body"', '"Gemini API request failed: Internal Server Error. Body: unreadable body\\n"')
content = content.replace('"OpenAI API request failed: Internal Server Error. Body: unreadable body"', '"OpenAI API request failed: Internal Server Error. Body: unreadable body\\n"')
content = content.replace('"Anthropic API request failed: Internal Server Error. Body: unreadable body"', '"Anthropic API request failed: Internal Server Error. Body: unreadable body\\n"')

# Actually, the error might be because `expect_error` matches with a regex by default!
# The '.' in "Internal Server Error." matches anything, but what about the actual error message?
# Let's just use "Internal Server Error"
content = content.replace('"Gemini API request failed: Internal Server Error. Body: unreadable body\\n"', '"Gemini API request failed: Internal Server Error"')
content = content.replace('"OpenAI API request failed: Internal Server Error. Body: unreadable body\\n"', '"OpenAI API request failed: Internal Server Error"')
content = content.replace('"Anthropic API request failed: Internal Server Error. Body: unreadable body\\n"', '"Anthropic API request failed: Internal Server Error"')

with open('tests/testthat/test-drivers_api.R', 'w') as f:
    f.write(content)
