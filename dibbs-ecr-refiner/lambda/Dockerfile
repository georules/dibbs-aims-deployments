FROM public.ecr.aws/lambda/nodejs:22

WORKDIR ${LAMBDA_TASK_ROOT}

# Copy package files
COPY . .

# Install dependencies
RUN npm install

RUN chmod 755 ${LAMBDA_TASK_ROOT}/index.js

# Set the CMD to your handler
CMD [ "index.handler" ]