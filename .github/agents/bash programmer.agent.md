name: Bash Programmer Agent
description: An agent that helps users write code in the Bash programming language.

on:
    - command: /bash
        arguments:
            - name: code
                type: string
                description: The code to be executed.

actions:
    - action: execute-code
        description: Executes the given code in a new file.
        inputs:
            - name: code
                type: string
        outputs:
            - name: output
                type: string
                description: The output of the executed code.
        implementation: |
            # Create a new file with the given code
            with open('new_file.sh', 'w') as f:
                    f.write(code)
            
            # Execute the code in the new file
            subprocess.run(['bash', 'new_file.sh'])
            
            # Read the output of the executed code
            with open('output.txt', 'r') as f:
                    output = f.read()
            
            return {
                    'output': output
            }