from os.path import join as opj, basename, splitext

# Функция для получения имени файла (без расширений), если файл имеет расширение .vcf.gz,
# то убираем ровно ".vcf.gz", иначе стандартно splitext.
def multiext(path):
    base = basename(path)
    if base.endswith(".vcf.gz"):
        return base[:-7]  # удаляем ".vcf.gz"
    else:
        return splitext(base)[0]

# Получаем список путей до входных файлов (ожидается строка с путями, разделёнными запятыми)
input_files = [x.strip() for x in config.get("input", "").split(",") if x.strip()]

# Выходная директория (по умолчанию "./results")
output_dir = config.get("output", "./results")
shell("mkdir -p " + output_dir)
RESULT_DIR = output_dir.rstrip("/") + "/"

# Создаём словарь: имя образца -> полный путь к файлу
sample2vcf = { multiext(f): f for f in input_files }
samples = list(sample2vcf.keys())

rule all:
    input:
        # Финальные resistance-отчёты находятся в каталоге dr
        expand("{result}dr/{sample}/{sample}.resistance.csv", sample=samples, result=RESULT_DIR)

rule rename:
    input:
        # Получаем путь до исходного файла для образца
        vcf = lambda w: expand("{vcf_file}", vcf_file=[ sample2vcf[w.sample] ])[0]
    output:
        # Выходной файл – переименованный VCF, с расширением .vcf.gz
        renamed = "{result}vcf_renamed/{sample}/{sample}.renamed.vcf.gz"
    shell:
        "bcftools annotate --rename-chrs scripts/chr.txt {input.vcf} -O z -o {output.renamed}"

rule annotate:
    input:
        # На вход берем переименованный файл
        vcf = "{result}vcf_renamed/{sample}/{sample}.renamed.vcf.gz"
    output:
        # Аннотированный VCF также сохраняется как .vcf.gz
        annotated = "{result}annotated_vcfs/{sample}/{sample}.annotated.vcf.gz"
    params:
        genome = "Mycobacterium_tuberculosis_h37rv"  # Замените на нужную базу/геном snpEff
    shell:
        # Здесь snpEff обрабатывает входной сжатый файл,
        # после чего вывод перенаправляется через bgzip для получения .vcf.gz
        "micromamba run -p env/snpEff snpEff ann -v {params.genome} {input.vcf} | bgzip -c > {output.annotated}"

rule tb_resistance:
    input:
        # На вход берём аннотированный, сжатый VCF-файл
        vcf = "{result}annotated_vcfs/{sample}/{sample}.annotated.vcf.gz"
    output:
        # Итоговый resistance-отчёт
        report = "{result}dr/{sample}/{sample}.resistance.csv"
    shell:
        "scripts/tb_resistance.py -i {input.vcf} -o {output.report} -d"
