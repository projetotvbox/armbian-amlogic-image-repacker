# 📖 Guia de Contribuição

> **Language / Idioma:** [English](CONTRIBUTING.en.md) | **[🟢 Português]**

Obrigado por considerar contribuir com o **Armbian Amlogic Image Repacker**!

Todas as contribuições são bem-vindas! Existem várias formas de colaborar com o projeto:

---

## 🐛 Reportando Bugs

Encontrou um problema? Ajude-nos a corrigir!

1. Acesse a aba [Issues](https://github.com/projetotvbox/armbian-amlogic-image-repacker/issues)
2. Verifique se o problema já foi reportado
3. Abra uma nova issue incluindo:
   - Sistema operacional e distribuição Linux utilizada
   - Modelo e versão da imagem Armbian utilizada
   - Log completo da execução (encontrado em `./logs/`)
   - Passos detalhados para reproduzir o problema
   - Mensagens de erro exibidas no terminal ou no dialog

---

## 📝 Melhorando Documentação

Documentação clara é essencial! Contribuições incluem:

- ✍️ Correções de typos e erros gramaticais
- 📚 Clarificações e melhorias de texto
- 🌐 Traduções para outros idiomas
- 📊 Exemplos adicionais ou diagramas
- 🎥 Tutoriais em vídeo ou imagens ilustrativas

> ⚠️ Ao atualizar documentação, mantenha sempre a paridade entre as versões **PT-BR** (`README.md`, `CONTRIBUTING.md`) e **Inglês** (`README.en.md`, `CONTRIBUTING.en.md`).

---

## 💻 Contribuindo com Código

### Fluxo Padrão de Contribuição

1. **Fork o repositório**
   ```bash
   # Clique em "Fork" no GitHub
   ```

2. **Clone seu fork**
   ```bash
   git clone https://github.com/seu-usuario/armbian-amlogic-image-repacker.git
   cd armbian-amlogic-image-repacker
   ```

3. **Crie uma branch para sua feature**
   ```bash
   git checkout -b feature/MinhaFeature
   # Exemplos de nomes:
   # - feature/suporte-novo-tamanho-boot
   # - fix/corrige-deteccao-uuid
   # - docs/atualiza-requisitos
   ```

4. **Faça suas alterações**
   - Edite os arquivos necessários
   - Teste extensivamente

5. **Commit suas mudanças**
   ```bash
   git add .
   git commit -m 'Adiciona suporte para tamanho customizado de boot'
   ```

   **Dicas para mensagens de commit:**
   - Use verbos no imperativo ("Adiciona", "Corrige", "Atualiza")
   - Seja específico e descritivo
   - Limite a primeira linha a 50–72 caracteres
   - Adicione detalhes no corpo se necessário

6. **Push para seu fork**
   ```bash
   git push origin feature/MinhaFeature
   ```

7. **Abra um Pull Request**
   - Acesse seu fork no GitHub
   - Clique em "Compare & pull request"
   - Preencha a descrição detalhadamente:
     - O que foi alterado?
     - Por que foi alterado?
     - Como testar?
     - Issues relacionadas (se houver)

---

## ✅ Boas Práticas

Ao contribuir com código, siga estas diretrizes:

### Testes

- ✅ Teste extensivamente antes de submeter
- ✅ Valide o resultado com uma imagem Armbian real
- ✅ Confirme que a imagem reempacotada boota corretamente no dispositivo
- ✅ Teste cenários de erro (ex: cancelamento pelo usuário, dependências faltando, imagem inválida)
- ✅ Verifique que o cleanup funciona corretamente em caso de falha (loop devices desanexados, partições desmontadas)

### Commits

- ✅ Mantenha commits atômicos (uma mudança lógica por commit)
- ✅ Use mensagens descritivas
- ✅ Evite commits com "WIP" ou "teste" no histórico final

### Código

- ✅ Siga o estilo de código existente (bash script)
- ✅ Use nomes de variáveis em maiúsculas e descritivos
- ✅ Adicione chamadas de log (`log_info`, `log_debug`, etc.) para operações relevantes
- ✅ Use `dialog_assert_exit_status` após comandos críticos
- ✅ Declare variáveis locais com `local` dentro de funções — e separe a declaração da atribuição quando capturar saída de comando:
   ```bash
   # Correto
   local MINHA_VAR
   MINHA_VAR=$(algum-comando)

   # Evitar — local engole o exit code do comando
   local MINHA_VAR=$(algum-comando)
   ```
- ✅ Adicione comentários para lógica complexa

### Documentação

- ✅ Atualize o README se adicionar ou alterar features
- ✅ Atualize comentários no código quando necessário
- ✅ Mantenha paridade entre versões PT-BR e EN

---

## 📋 Checklist de Pull Request

Antes de submeter, verifique:

- [ ] Script testado com uma imagem Armbian real
- [ ] Imagem reempacotada validada (boot funcional no dispositivo)
- [ ] Documentação atualizada em PT-BR e EN (se aplicável)
- [ ] Commits organizados e com mensagens descritivas
- [ ] Nenhum arquivo temporário, de log ou imagem `.img` incluído no commit
- [ ] Variáveis locais declaradas corretamente dentro de funções
- [ ] Mensagens de erro claras e úteis ao usuário

---

## 💡 Dúvidas?

Se tiver dúvidas sobre como contribuir:

1. Leia a documentação completa no [README.md](README.md)
2. Consulte issues existentes no [GitHub Issues](https://github.com/projetotvbox/armbian-amlogic-image-repacker/issues)
3. Abra uma discussão em [Discussions](https://github.com/projetotvbox/armbian-amlogic-image-repacker/discussions)

---

## 🙏 Agradecimentos

**🎉 Toda contribuição, por menor que seja, faz diferença!**

Este projeto é mantido por voluntários e faz parte de uma iniciativa social do **IFSP Campus Salto**. Sua contribuição ajuda a:

- ♻️ Reduzir lixo eletrônico
- 🎓 Promover inclusão digital
- 🔧 Ensinar tecnologia para estudantes
- 🌍 Criar impacto social positivo

**Obrigado por fazer parte dessa iniciativa!** ❤️

---

## 📄 Código de Conduta

Este projeto segue os princípios de respeito, colaboração e inclusão. Esperamos que todos os contribuidores:

- Sejam respeitosos e construtivos
- Aceitem críticas construtivas
- Foquem no melhor para a comunidade
- Demonstrem empatia com outros membros

---

**Desenvolvido para o Projeto TVBox - Instituto Federal de São Paulo (IFSP), Campus Salto**
