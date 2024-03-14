FROM mcr.microsoft.com/azure-cli

COPY ./script.sh ./

ENV URL=
ENV THRESHOLD=
ENV USERNAME=
ENV PASSWORD=
ENV TENANT_ID=

RUN echo "I am inside the container"
RUN apk update && apk add --no-cache curl
RUN chmod +x ./script.sh

CMD ["./script.sh"]
