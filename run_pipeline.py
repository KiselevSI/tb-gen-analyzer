#!/usr/bin/env python3
import argparse
import subprocess

def main():
    parser = argparse.ArgumentParser(
        description="Запуск пайплайна Snakemake для аннотации VCF файлов, переименования хромосом и генерации resistance-отчетов"
    )
    # Флаг -i принимает список путей до VCF файлов
    parser.add_argument("-i", "--input", required=True, nargs="+",
                        help="Список путей до VCF файлов")
    parser.add_argument("-o", "--output", required=True,
                        help="Папка для сохранения результатов")
    parser.add_argument("-t", "--threads", type=int, default=1,
                        help="Количество потоков для распараллеливания")
    args = parser.parse_args()

    # Формируем строку входных файлов, разделённых запятыми
    input_str = ",".join(args.input)

    cmd = ["micromamba", "run", "-p" "env/snakemake",
        "snakemake",
        "--snakefile", "Snakefile",
        "--config", f"input={input_str}", f"output={args.output}",
        "-j", str(args.threads)
    ]

    print("Запуск команды:", " ".join(cmd))
    subprocess.run(cmd)

if __name__ == "__main__":
    main()
