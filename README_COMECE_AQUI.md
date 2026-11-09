# 🏆 Bora Jogar — Beta com e-mail, senha e perfil individual

Esta versão mantém o **visual V4**, mapa + lista, filtros para **Praia Grande, Santos, São Vicente e Mongaguá**, criação de partidas e inscrições. A mudança foi implementada em **09/11/2026** no código e **no projeto Supabase já existente**.

## O que está feito

- **Supabase Bora Jogar Beta**, região de São Paulo: tabelas `games`, `registrations` e `profiles` com proteção **RLS**. A migração `database/migration_email_senha_perfis.sql` foi aplicada no banco remoto em 09/11/2026.
- **Cadastro** com nome, cidade, esporte favorito, e-mail e senha; **login** por e-mail/senha; **sair** da conta.
- O app **não faz mais login anônimo** quando conectado ao Supabase e exige sessão com e-mail confirmado. Perfis ficam associados ao ID do usuário e são acessíveis apenas pelo próprio atleta.
- Partidas e inscrições ficam vinculadas à conta e sincronizam pelo banco compartilhado.
- A foto do perfil ainda fica no próprio dispositivo (as demais informações ficam no banco). O projeto inclui preparo Capacitor para Android/iOS e GitHub Actions para APK de testes.

## ⚠️ O que falta conferir antes de convidar atletas

1. Abra [Supabase — Authentication > Providers](https://supabase.com/dashboard/project/jjxqfqejhgteqcqxwzks/auth/providers) e em **Email** confira que login por e-mail está ativado e **Confirm email** está habilitado. Em projetos hospedados, esta é normalmente a configuração padrão, mas não consegui ler essa configuração específica pelas ferramentas disponíveis. Desative **Anonymous Sign-Ins** se ainda estiver habilitado (as políticas do banco já bloqueiam sessões anônimas).
2. Abra [Supabase — URL Configuration](https://supabase.com/dashboard/project/jjxqfqejhgteqcqxwzks/auth/url-configuration) e configure o endereço público do app (**Site URL**) quando a hospedagem estiver definida. Sem domínio configurado, links de confirmação podem redirecionar para `localhost` após confirmar a conta. A confirmação ainda pode ocorrer, mas o retorno ao app pode falhar. Para iOS/Android, configure deep links do Capacitor antes da publicação beta para abrir links dentro do aplicativo.
3. O envio de e-mails depende do provedor configurado no Supabase e tem limites. Para testes com várias pessoas, considere SMTP próprio. Confirme entregabilidade antes de enviar convites.
4. Teste em **dois celulares** com contas diferentes: criar conta, confirmar e-mail, entrar, editar perfil, criar partida, participar, sair e entrar de novo. O teste com a infraestrutura real ainda não foi realizado.

## Instalar e executar no Windows (Android)

1. Extraia o ZIP e abra a pasta `Bora_Jogar_App_Beta`.
2. Com Node.js 22+ instalado, rode `npm install` e `npm run verificar`.
3. Use `PREPARAR_ANDROID_WINDOWS.ps1` ou os comandos `npx cap add android` (uma vez), `npx cap sync android` e `npx cap open android` com Android Studio.
4. No Android Studio: **Build > Build APK(s)**. Compartilhe **apenas o APK de teste** com participantes convidados. Alternativamente, envie o repositório ao GitHub e execute `.github/workflows/android-beta.yml` para gerar um APK debug por GitHub Actions.

## Instalar e executar no Mac (iOS / TestFlight)

1. Em Mac com Xcode e Node.js, rode `npm install`, `npx cap add ios`, `npx cap sync ios` e `npx cap open ios`.
2. Configure o Bundle ID e a **equipe Apple Developer** com a autorização do dono da conta, gere um **Archive** e envie ao **App Store Connect**.
3. Ative o build no **TestFlight**, forneça dados de teste e convide os participantes após a revisão necessária. **Somente instalar o TestFlight não dá acesso para publicar builds.**

## Configuração e banco

- `www/config.js` já contém **apenas a chave pública** do projeto `jjxqfqejhgteqcqxwzks`. Nunca coloque `service_role` ou `secret` no aplicativo.
- `database/schema.sql`: criação completa de um banco novo, incluindo regras para contas individuais.
- `database/migration_email_senha_perfis.sql`: alteração de banco já existente. **NÃO execute novamente no projeto atual**; ela já foi aplicada.
- `npm run preview`: abre a versão web local em `http://localhost:8080` (sem interface de app nativo).
- Mudanças em `www/` precisam de `npx cap sync android`/`ios` antes de novos builds.

**Status de entrega:** código-fonte atualizado e banco remoto alterado. Esta versão **não contém APK ou IPA compilados** e **ainda não foi enviada ao GitHub nem ao TestFlight**, porque esses passos requerem um repositório acessível, ferramentas nativas e a equipe Apple Developer. Compilação e testes reais ainda estão pendentes.
