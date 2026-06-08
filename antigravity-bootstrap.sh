#!/bin/bash
set -e

# Configuración de colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Iniciando Despliegue Zero-Touch (ANTIGRAVITY) para NEAT S.A. DE C.V. ===${NC}"

# Variables
REPO_NAME="neat-landing"
GITHUB_USER=$(gh api user -q ".login")

echo -e "\n${BLUE}[1/5] Inicializando Repositorio Git...${NC}"
git init
git add .
git commit -m "feat: Initial commit - Premium Corporate Landing Page" || echo "Nothing to commit"

echo -e "\n${BLUE}[2/5] Creando Repositorio en GitHub...${NC}"
if gh repo view $GITHUB_USER/$REPO_NAME &>/dev/null; then
    echo -e "${GREEN}El repositorio ya existe en GitHub.${NC}"
else
    gh repo create $REPO_NAME --public --source=. --remote=origin --push
fi

echo -e "\n${BLUE}[3/5] Extrayendo Credenciales de Vercel...${NC}"
# Extrayendo TOKEN de Vercel (macOS default path)
VERCEL_TOKEN_PATH="$HOME/Library/Application Support/com.vercel.cli/auth.json"
if [ ! -f "$VERCEL_TOKEN_PATH" ]; then
    echo -e "${RED}Error: Vercel CLI auth.json no encontrado en $VERCEL_TOKEN_PATH${NC}"
    exit 1
fi
VERCEL_TOKEN=$(cat "$VERCEL_TOKEN_PATH" | grep '"token"' | head -1 | awk -F '"' '{print $4}')

# Verificando si existe .vercel/project.json para extraer ORG_ID y PROJECT_ID
if [ ! -f ".vercel/project.json" ]; then
    echo -e "${BLUE}Enlazando proyecto con Vercel...${NC}"
    vercel link --yes
fi
VERCEL_ORG_ID=$(cat .vercel/project.json | grep '"orgId"' | awk -F '"' '{print $4}')
VERCEL_PROJECT_ID=$(cat .vercel/project.json | grep '"projectId"' | awk -F '"' '{print $4}')

echo -e "\n${BLUE}[4/5] Inyectando Secretos en GitHub Actions...${NC}"
gh secret set VERCEL_TOKEN -b "$VERCEL_TOKEN" -R "$GITHUB_USER/$REPO_NAME"
gh secret set VERCEL_ORG_ID -b "$VERCEL_ORG_ID" -R "$GITHUB_USER/$REPO_NAME"
gh secret set VERCEL_PROJECT_ID -b "$VERCEL_PROJECT_ID" -R "$GITHUB_USER/$REPO_NAME"
echo -e "${GREEN}Secretos inyectados correctamente.${NC}"

echo -e "\n${BLUE}[5/5] Realizando Push para activar GitHub Actions...${NC}"
git branch -M main
git push -u origin main

echo -e "\n${GREEN}=== Despliegue Zero-Touch completado con éxito ===${NC}"
echo -e "Puedes monitorear el despliegue en: https://github.com/$GITHUB_USER/$REPO_NAME/actions"
