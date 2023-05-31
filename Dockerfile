# --- (A) Build App ---

# Use the official .NET Core SDK image as the base image
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build-env

# Set the working directory in the container
WORKDIR /app

# Copy the project file and restore dependencies
COPY ["**/**/*.csproj", "./"]
RUN for f in ./*.csproj; do dotnet restore $f; done

# Copy the entire project and build the app
COPY . ./
RUN dotnet publish -c Release -o out

# --- (B) Copy the output to the Runtime image ---

# Build the runtime image
FROM mcr.microsoft.com/dotnet/aspnet:7.0
WORKDIR /app
COPY --from=build-env /app/out .

# --- (C) Security ---

# Expose 8000 for appuser (non-root users cannot use ports less than 1024 & our app will run as appuser)
ENV ASPNETCORE_URLS=http://+:8000
EXPOSE 8000
EXPOSE 443

# As we don't wanna run it using an admin account for security reasons, add a new "appuser" user and group to run the service with
RUN groupadd --gid 5000 appuser \
    && useradd --home-dir /app --uid 5000 --gid 5000 --shell /bin/sh appuser
RUN chown -R appuser:appuser .
USER appuser

# --- (D) Finale - Entry Point ---

# Define the entry point for the container
ENTRYPOINT ["dotnet", "Dummy.WebApi.dll"]
