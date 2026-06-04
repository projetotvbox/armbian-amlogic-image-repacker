# Armbian Amlogic Image Repacker

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Shell Script](https://img.shields.io/badge/Shell_Script-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Armbian](https://img.shields.io/badge/Armbian-Focused-orange.svg)](https://www.armbian.com/)
[![AMLogic](https://img.shields.io/badge/AMLogic-S905X%2FX2%2FX3-blue.svg)](https://en.wikipedia.org/wiki/Amlogic)
[![Version](https://img.shields.io/badge/Version-1.0-informational.svg)]()

> **Language / Idioma:** [English](README.en.md) | **[🟢 Português]**

Script interativo para reempacotar imagens Armbian de partição única (ext4) para o formato dual partition (FAT32 + ext4) exigido pela grande maioria das TV Boxes AMLogic para realizar o boot.

**Autores:** [Pedro Rigolin](https://github.com/pedrohrigolin) e [Fábio Haruo](https://github.com/Haruo09)

**Projeto:** Desenvolvido para o [Projeto TVBox](https://github.com/projetotvbox) do **Instituto Federal de São Paulo (IFSP)**, Campus Salto

---

## 📑 Sumário

- [📦 Sobre o Projeto TVBox](#-sobre-o-projeto-tvbox)
- [🔍 Visão Geral](#-visão-geral)
  - [🎯 O Problema e a Solução](#-o-problema-e-a-solução)
  - [✨ Características](#-características)
- [⚙️ Requisitos](#️-requisitos)
  - [Hardware](#hardware)
  - [Sistema Operacional](#sistema-operacional)
  - [Dependências](#dependências)
  - [Espaço em Disco](#espaço-em-disco)
- [🚀 Como Usar](#-como-usar)
  - [Estrutura de Diretórios](#estrutura-de-diretórios)
  - [Executando o Script](#executando-o-script)
  - [Fluxo de Operação](#fluxo-de-operação)
- [🔧 Detalhes Técnicos](#-detalhes-técnicos)
  - [Layout de Partições](#layout-de-partições)
  - [Arquivos Configurados Automaticamente](#arquivos-configurados-automaticamente)
- [⚠️ Considerações sobre Tamanho da Imagem](#️-considerações-sobre-tamanho-da-imagem)
  - [Por Que o Tamanho é Mantido](#por-que-o-tamanho-é-mantido)
  - [Como Verificar o Espaço Disponível](#como-verificar-o-espaço-disponível)
  - [Como Redimensionar se Necessário](#como-redimensionar-se-necessário)
- [📋 Logs](#-logs)
- [🔧 Troubleshooting](#-troubleshooting)
- [👥 Contribuidores](#-contribuidores)
- [📄 Licença](#-licença)
- [⚠️ Aviso Legal](#️-aviso-legal)

---

## 📦 Sobre o Projeto TVBox

Este instalador foi desenvolvido como parte do **Projeto TVBox do IFSP Campus Salto**, uma iniciativa que visa dar novo propósito a dispositivos TV Box apreendidos pela Receita Federal.

O projeto realiza a descaracterização desses equipamentos, transformando-os em **mini PCs funcionais** com Linux, proporcionando:

- Reutilização de hardware que seria descartado
- Inclusão digital através de doações para comunidades
- Redução de impacto ambiental (e-waste)
- Capacitação técnica de estudantes

---

## 🔍 Visão Geral

### 🎯 O Problema e a Solução

As imagens oficiais do **Armbian** utilizam por padrão uma **partição única em ext4**. No entanto, a grande maioria das TV Boxes AMLogic (SoCs S905X/X2/X3/X4) exige um **particionamento dual** para realizar o boot corretamente:

```
Partição 1: BOOT (FAT32) → Kernel, DTB, scripts de boot
Partição 2: ROOTFS (ext4) → Sistema de arquivos raiz
```

Realizar essa conversão manualmente é um processo trabalhoso e sujeito a erros. Este script **automatiza completamente** o processo, oferecendo uma interface interativa (TUI) que guia o usuário por cada etapa.

### ✨ Características

- ✅ **Interface interativa** com menus `dialog` (TUI)
- ✅ **Seleção de imagem** via menu, com suporte a múltiplos arquivos `.img`
- ✅ **Escolha do tamanho** da partição de boot (256 MiB ou 512 MiB)
- ✅ **Formatação automática** das partições (FAT32 e EXT4)
- ✅ **Cópia e reorganização** dos arquivos de boot e rootfs
- ✅ **Atualização automática** de `armbianEnv.txt` e `fstab` com os novos UUIDs
- ✅ **Logging detalhado** de toda a execução em `./logs/`
- ✅ **Cleanup automático** em caso de erro ou interrupção (desmonta partições, desanexa loop devices)
- ✅ **Verificação de dependências** antes de iniciar

---

## ⚙️ Requisitos

### Hardware

| Componente | Requisito |
|------------|-----------|
| RAM | ≥ 8 GB |
| Arquitetura | x86_64, aarch64 ou riscv64 |
| Espaço em disco | ≥ 2,5× o tamanho da imagem original |

### Sistema Operacional

O script foi desenvolvido e testado em ambientes **Debian/Ubuntu** e é recomendado para uso nessas distribuições. Pode funcionar em outras distros Linux, mas sem garantias.

Os requisitos de sistema operacional seguem os mesmos do Armbian. Como esses requisitos podem ser atualizados pela equipe do Armbian, consulte sempre a documentação oficial mais recente:

> 📖 **[Requisitos oficiais do Armbian Build Framework](https://docs.armbian.com/Developer-Guide_Build-Preparation/)**

Como referência, os requisitos atuais conhecidos são:

| Ambiente | Sistema |
|----------|---------|
| Build nativo | Armbian ou Ubuntu 24.04 (Noble) |
| Containerizado | Qualquer Linux com suporte a Docker |
| Windows | WSL2 com Armbian/Ubuntu 24.04 |

> ⚠️ **Nota:** Esses requisitos podem mudar conforme o Armbian evolui. Sempre verifique a documentação oficial em caso de dúvida.

### Dependências

O script verifica automaticamente a presença das seguintes ferramentas antes de executar. Instale-as caso estejam ausentes:

| Binário | Descrição |
|---------|-----------|
| `parted` | Particionamento de disco |
| `dialog` | Interface TUI |
| `mkfs.vfat` | Formatação FAT32 (pacote `dosfstools`) |
| `mkfs.ext4` | Formatação EXT4 (pacote `e2fsprogs`) |
| `rsync` | Cópia de arquivos com preservação de atributos |
| `blkid` | Leitura de UUIDs de partições |
| `losetup` | Gerenciamento de loop devices |
| `pv` | Monitoramento de progresso |

**Instalação no Debian/Ubuntu:**

```bash
sudo apt install parted dialog dosfstools e2fsprogs rsync util-linux pv
```

**Instalação no Arch Linux:**

```bash
sudo pacman -S parted dialog dosfstools e2fsprogs rsync util-linux pv
```

**Instalação no Fedora/RHEL:**

```bash
sudo dnf install parted dialog dosfstools e2fsprogs rsync util-linux pv
```

### Espaço em Disco

O script cria uma cópia completa da imagem original. Recomenda-se ter disponível pelo menos **2,5× o tamanho da imagem original** no disco onde o script é executado, para acomodar a imagem original, a imagem reempacotada e os arquivos temporários de trabalho.

Exemplo: para uma imagem de 4 GB, tenha ao menos 10 GB livres.

---

## 🚀 Como Usar

### Estrutura de Diretórios

Antes de executar, o repositório deve ter a seguinte estrutura:

```
armbian-amlogic-image-repacker/
├── armbian-amlogic-image-repacker.sh
├── original-images/          ← Coloque seus arquivos .img aqui
│   └── sua-imagem-armbian.img
├── repacked-images/          ← As imagens reempacotadas serão salvas aqui
└── logs/                     ← Logs de execução
```

> 💡 Os diretórios `original-images/` e `repacked-images/` são criados automaticamente pelo script caso não existam.

### Executando o Script

```bash
# Clone o repositório
git clone https://github.com/projetotvbox/armbian-amlogic-image-repacker.git
cd armbian-amlogic-image-repacker

# Coloque sua imagem Armbian (.img) em original-images/
cp /caminho/para/sua-imagem.img original-images/

# Execute como root
sudo bash armbian-amlogic-image-repacker.sh
```

### Fluxo de Operação

1. **Verificação de dependências** — o script confirma que todas as ferramentas necessárias estão disponíveis
2. **Seleção da imagem** — menu interativo lista todos os `.img` encontrados em `original-images/`
3. **Validação da imagem** — confirma que a imagem selecionada possui filesystem ext4 (imagem Armbian padrão)
4. **Seleção do tamanho do boot** — escolha entre 256 MiB e 512 MiB para a partição FAT32
5. **Criação da nova imagem** — cria um arquivo de imagem com o mesmo tamanho da original
6. **Particionamento** — cria a tabela MBR com as duas partições (FAT32 + ext4)
7. **Formatação** — formata as partições com os labels `BOOT` e `ROOTFS`
8. **Cópia dos arquivos** — distribui os arquivos da imagem original nas partições corretas
9. **Atualização de configuração** — atualiza `armbianEnv.txt` e `fstab` com os novos UUIDs
10. **Finalização** — desmonta tudo, remove arquivos temporários e exibe o resultado

A imagem reempacotada é salva em `repacked-images/repacked_<nome-original>.img`.

---

## 🔧 Detalhes Técnicos

### Layout de Partições

| Partição | Tipo | Label | Início | Fim | Conteúdo |
|----------|------|-------|--------|-----|----------|
| p1 | FAT32 | `BOOT` | 1 MiB | 256 MiB ou 512 MiB | Kernel, DTBs, `armbianEnv.txt`, scripts de boot |
| p2 | EXT4 | `ROOTFS` | Fim de p1 | 100% | Sistema de arquivos raiz completo |

A tabela de partições utilizada é **MBR (msdos)**, com a flag `boot` e `lba` ativas na partição 1, conforme exigido pela maioria dos bootloaders AMLogic.

### Sobre o Espaço Anterior à Primeira Partição (MBR Gap)

Ao inspecionar a imagem reempacotada, você notará que a primeira partição começa no setor 2048 (offset de 1 MiB), enquanto a imagem Armbian original pode iniciar no setor 8192 ou em outro offset maior. Essa diferença é **intencional e não representa um problema**.

Em arquiteturas convencionais, o espaço entre o MBR e o início da primeira partição (chamado de "MBR gap" ou "embedding area") é utilizado para armazenar o U-Boot de primeiro estágio (SPL — Secondary Program Loader). Nesse caso, o bootloader é carregado diretamente do dispositivo de boot (cartão SD ou pendrive).

**Nas TV Boxes AMLogic, esse mecanismo não é utilizado.** O U-Boot já vem gravado permanentemente na memória eMMC interna do dispositivo, de fábrica. Quando o dispositivo é ligado, o U-Boot da eMMC é quem assume o controle — ele não lê nem depende do espaço anterior à primeira partição do pendrive ou cartão SD. Esse espaço é simplesmente ignorado.

O que o U-Boot das TV Boxes AMLogic de fato procura é o conteúdo da **partição FAT32**: scripts de boot como `s905_autoscript`, `aml_autoscript` ou `boot.ini`, que instruem o bootloader sobre como carregar o kernel. São exatamente esses arquivos que o script copia para a partição `BOOT` durante o reempacotamento.

> 💡 **Escopo do script:** Este script não tem a intenção de preservar ou manipular o MBR gap da imagem original. Técnicas de chainload, autoscripts e qualquer configuração de boot específica para o dispositivo devem ser aplicadas **após** o reempacotamento, diretamente na partição FAT32 da imagem resultante.
>
> 📂 **Autoscripts:** O Projeto TVBox mantém um fork dos autoscripts desenvolvidos por [devmfc](https://github.com/devmfc), adaptados para uso com Armbian em dispositivos AMLogic. Caso precise de autoscripts prontos para configurar o boot, acesse: [projetotvbox/amlogic-bootscripts-Armbian](https://github.com/projetotvbox/amlogic-bootscripts-Armbian)

### Arquivos Configurados Automaticamente

**`armbianEnv.txt`** (partição BOOT):

O script remove qualquer entrada `rootdev` existente e insere a entrada correta com o UUID da nova partição rootfs:

```
rootdev=UUID=<novo-uuid-da-rootfs>
```

**`/etc/fstab`** (partição ROOTFS):

O fstab é reescrito com as entradas corretas para o novo layout:

```
# <file system>  <mount point>  <type>  <options>                                  <dump>  <pass>
tmpfs            /tmp           tmpfs   defaults,nosuid                            0       0
UUID=<rootfs>    /              ext4    defaults,noatime,commit=600,errors=remount-ro  0   1
UUID=<boot>      /boot          vfat    defaults,noatime,umask=0077                0       2
```

---

## ⚠️ Considerações sobre Tamanho da Imagem

### Por Que o Tamanho é Mantido

O script cria a imagem reempacotada com **exatamente o mesmo tamanho** da imagem original. Isso é intencional: as imagens Armbian oficiais já incluem espaço não alocado suficiente para acomodar a partição FAT32 de boot (até 512 MiB) sem precisar aumentar o tamanho total da imagem.

Isso significa que, na prática, **você não precisa se preocupar com espaço** ao usar imagens Armbian oficiais. O reempacotamento não vai estourar o tamanho.

### Como Verificar o Espaço Disponível

Caso você queira confirmar que há espaço suficiente antes de reempacotar, ou se estiver usando uma imagem customizada de tamanho reduzido, siga os passos abaixo.

**1. Verifique o tamanho total e o layout de partições da imagem original:**

```bash
parted sua-imagem.img unit MiB print
```

Exemplo de saída para uma imagem Armbian padrão:

```
Model:  (file)
Disk /path/to/sua-imagem.img: 3932 MiB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags:

Number  Start    End      Size     Type     File system  Flags
 1      1.00MiB  3931MiB  3930MiB  primary  ext4
```

**2. Calcule o espaço disponível para a nova partição de boot:**

Subtraia o tamanho do conteúdo real da partição do tamanho total da imagem. Para ver quanto espaço está efetivamente usado na partição:

```bash
# Anexa a imagem como loop device
sudo losetup -fP --show sua-imagem.img
# Exemplo: retorna /dev/loop0

# Verifica o uso real do filesystem
sudo df -h /dev/loop0p1
# ou
sudo dumpe2fs -h /dev/loop0p1 | grep -E "Block count|Free blocks|Block size"

# Desanexa ao terminar
sudo losetup -d /dev/loop0
```

Se a diferença entre o tamanho total da imagem e o conteúdo usado for maior que o tamanho do boot que você quer criar (256 MiB ou 512 MiB), o reempacotamento funcionará sem problemas.

### Como Redimensionar se Necessário

Se a imagem for muito enxuta e não houver espaço suficiente para a partição de boot, você precisa aumentar o tamanho da imagem antes de reempacotar. Existem duas abordagens:

**Opção A — `qemu-img` (recomendado, mais seguro):**

```bash
# Aumenta a imagem em 512 MiB (ajuste conforme necessário)
qemu-img resize sua-imagem.img +512M
```

> ⚠️ O `qemu-img resize` apenas aumenta o arquivo de imagem. O espaço adicional fica não alocado e estará disponível para o particionamento pelo script.

**Opção B — `truncate` (alternativa mais simples):**

```bash
# Verifica o tamanho atual em bytes
stat -c%s sua-imagem.img

# Aumenta para um tamanho específico (exemplo: 5 GiB)
truncate -s 5G sua-imagem.img
```

> ⚠️ O `truncate` com um tamanho maior apenas estende o arquivo; não corrompe os dados existentes. Nunca use `truncate` para *reduzir* uma imagem.

**Verificando após o redimensionamento:**

```bash
parted sua-imagem.img unit MiB print
```

Confirme que o tamanho total da imagem agora é suficiente para os dados existentes mais a partição de boot desejada.

---

## 📋 Logs

Cada execução gera um log detalhado em `./logs/`, com o formato:

```
logs/armbian-repacker_YYYYMMDD_HHMMSS.log
```

O log registra todas as operações realizadas, incluindo comandos executados, valores de variáveis, estados de transição e erros. São mantidos os **10 logs mais recentes**; os anteriores são removidos automaticamente.

---

## 🔧 Troubleshooting

### "Missing required binaries"

O script detectou que uma ou mais dependências não estão instaladas. Instale os pacotes correspondentes conforme a seção [Dependências](#dependências) e execute novamente.

### "No .img files found"

Nenhum arquivo `.img` foi encontrado em `original-images/`. Certifique-se de que:
- O arquivo foi copiado para o diretório correto
- O arquivo tem extensão `.img` (não `.img.gz` ou outro formato comprimido)

Se a imagem estiver comprimida (`.img.xz`, `.img.gz`), descompacte-a primeiro:

```bash
# Para .img.xz (formato comum do Armbian)
xz -d sua-imagem.img.xz

# Para .img.gz
gunzip sua-imagem.img.gz
```

### "Error: expected filesystem 'ext4'"

A imagem selecionada não possui ext4 na primeira partição. Este script foi projetado para imagens Armbian padrão (single partition ext4). Verifique se está usando a imagem correta.

### A imagem reempacotada não boota

Verifique:
1. Se o `armbianEnv.txt` foi atualizado corretamente — o UUID de `rootdev` deve corresponder ao UUID da partição rootfs da imagem reempacotada
2. Se o `/etc/fstab` foi atualizado — os UUIDs devem corresponder às novas partições
3. O log da execução em `./logs/` para identificar qualquer erro durante o processo

Para verificar os UUIDs da imagem reempacotada:

```bash
sudo losetup -fP --show repacked-images/repacked_sua-imagem.img
# Exemplo: retorna /dev/loop0

sudo blkid /dev/loop0p1 /dev/loop0p2

sudo losetup -d /dev/loop0
```

### Loop device não foi liberado após erro

Em caso de interrupção abrupta, pode haver loop devices órfãos. Liste e remova manualmente:

```bash
# Lista todos os loop devices em uso
sudo losetup -a

# Remove um específico
sudo losetup -d /dev/loopX
```

---

## 👥 Contribuidores

### Autores

- **[Pedro Rigolin](https://github.com/pedrohrigolin)** — Desenvolvimento principal
- **[Fábio Haruo](https://github.com/Haruo09)** — Desenvolvimento principal

### Como Contribuir

Contribuições são bem-vindas! Você pode:

- 🐛 **Reportar bugs** abrindo uma issue
- 📝 **Melhorar a documentação**
- 💻 **Contribuir com código** via pull request

---

## 📄 Licença

Este projeto é licenciado sob a **MIT License**.

```
MIT License

Copyright (c) 2026 Pedro Rigolin, Fábio Haruo

Developed for Projeto TVBox - Instituto Federal de São Paulo (IFSP), Campus Salto
```

Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## ⚠️ Aviso Legal

⚠️ **USE POR SUA CONTA E RISCO**

Este script manipula imagens de disco e realiza operações de particionamento e formatação. Embora opere sobre arquivos de imagem (não diretamente em discos físicos), sempre:

- Mantenha um backup da imagem original antes de reempacotar
- Verifique que tem espaço em disco suficiente antes de executar
- Execute apenas como root, em um ambiente controlado

Os autores não se responsabilizam por perda de dados ou imagens corrompidas resultantes do uso deste script.

---

*Feito com 🐧 no IFSP Salto · Tecnologia a serviço da educação pública*
