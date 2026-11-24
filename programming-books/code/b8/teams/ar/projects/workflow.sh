$ python3 workflow.py
on: ['pull_request'] | permissions: {'contents': 'read'} | timeout: 10
 - actions/checkout@v4 
 - actions/setup-node@v4 
 - npm install -g @anthropic-ai/claude-code 
 - sh ci/review.sh (secret)
