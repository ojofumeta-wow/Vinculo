# Vínculo – Diario de tu mascota (WoW: Forever)

Guarda la historia de cada mascota de cazador: el día y el lugar en que os conocisteis, combates superados, jefes derrotados, zonas y mazmorras visitadas, tiempo juntos, comidas, caídas y resurrecciones, 21 logros propios y una línea del tiempo de vuestra aventura.

## Sin molestar

- **Personalidad:** tu mascota gana un carácter según cómo jugáis (Glotona, Temeraria, Trotamundos, Matagigantes, Incansable, Invencible, Leal o Fiel). Aparece en su ficha y, al pasar el ratón por encima, explica por qué.
- **Aniversarios:** al cumplir 1, 3 y 6 meses, y cada año, deja una línea en el chat y en la Historia.
- **Resumen semanal:** el primer día que juegas cada semana, una sola línea en el chat con la mascota que más te acompañó.
- **Opciones** (botón del engranaje): cada aviso se puede apagar, y los logros pueden avisar solo en el chat en vez de con una ventanita. El mensaje de bienvenida sale solo la primera vez.

## Instalación

Copia la carpeta `Vinculo` en `World of Warcraft/_forever_/Interface/AddOns/` y reinicia el juego.

## Comandos

- `/vinculo` o `/diario`: abre el diario.
- `/vinculo avisos`: activa o desactiva los avisos de logros.
- `/vinculo compartir`: comparte la ficha de tu mascota actual en banda, grupo o hermandad.

## Cómo cuenta las cosas

Forever aplica las restricciones de addons de Midnight: los addons no pueden leer el registro de combate y algunos datos son "secretos" durante el combate. Por eso Vínculo:

- Cuenta **combates superados**: el combate termina con tu mascota y contigo vivos. No puede saber si mataste al enemigo o si huiste.
- Lee nombre, nivel y lealtad **fuera de combate**.
- Detecta las caídas cuando la mascota desaparece en combate sin que la hayas retirado, o cuando lanzas Revivir mascota.

Los datos se guardan por personaje en `VinculoDB`. El diario de cada mascota empieza la primera vez que la invocas con el addon instalado.
