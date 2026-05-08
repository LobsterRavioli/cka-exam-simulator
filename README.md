# CKA Exam Simulator

Generate randomised CKA practice exams from a local exercise bank. Each run
produces an `exam.md` (18 questions) and a `setup.bash` (Killercoda environment
prep) inside the `exams/` folder.

## Quick start

```bash
chmod +x exam-gen.sh

./exam-gen.sh cka-prep-2025-v2          # random CKA Prep 2025 v2 exam
./exam-gen.sh dumbitguy         # random DumbitGuy exam
./exam-gen.sh itkiddie          # random ITKiddie exam
./exam-gen.sh cka-prep-2025-v2 --seed 42  # reproducible selection
```

The output lands in `exams/<timestamp>-<type>/`:

```
exams/2024-06-01_143000-cka-prep-2025-v2/
├── exam.md      # open this to read the questions
└── setup.bash   # run this on Killercoda before starting
```

## Folder structure

```
topics/
  01-storage-pv-pvc/
    cka-prep-2025-v2/
      01/                  <- variation 01
        question.txt
        setup.bash
        solution.txt
      02/                  <- variation 02 (you add it)
        ...
    dumbitguy/             <- empty, add your own variations
    itkiddie/              <- empty, add your own variations
  02-storage-storageclass/
  ...
  18-cluster-tls/
```

### 18 topics (CKA curriculum)

| # | Topic | Domain |
|---|-------|--------|
| 01 | storage-pv-pvc | Storage (10%) |
| 02 | storage-storageclass | Storage (10%) |
| 03 | networking-services | Services & Networking (20%) |
| 04 | networking-ingress | Services & Networking (20%) |
| 05 | networking-gateway | Services & Networking (20%) |
| 06 | networking-networkpolicy | Services & Networking (20%) |
| 07 | networking-cni | Services & Networking (20%) |
| 08 | workloads-deployments | Workloads & Scheduling (15%) |
| 09 | workloads-sidecar | Workloads & Scheduling (15%) |
| 10 | workloads-resources | Workloads & Scheduling (15%) |
| 11 | workloads-hpa | Workloads & Scheduling (15%) |
| 12 | workloads-scheduling | Workloads & Scheduling (15%) |
| 13 | workloads-priorityclass | Workloads & Scheduling (15%) |
| 14 | cluster-rbac | Cluster Architecture (25%) |
| 15 | cluster-crd | Cluster Architecture (25%) |
| 16 | cluster-etcd | Cluster Architecture (25%) |
| 17 | cluster-helm | Cluster Architecture (25%) |
| 18 | cluster-tls | Cluster Architecture (25%) |

## Adding exercises

1. Pick the relevant topic folder, e.g. `topics/04-networking-ingress/cka-prep-2025-v2/`
2. Create a numbered subfolder: `02/`
3. Add three files:

| File | Purpose |
|------|---------|
| `question.txt` | The task description (markdown) |
| `setup.bash` | kubectl commands to set up the environment on Killercoda |
| `solution.txt` | Reference solution (markdown + code blocks) |

The generator picks **one variation at random** per topic per run.

## Requirements

- bash 3.2+ (macOS default is fine)
- `date`, `find`, `cat` (standard POSIX tools)
- Exercises run on [Killercoda](https://killercoda.com/) Ubuntu playground
