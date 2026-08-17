import subprocess, json, sys, os

def git_credential_fill(protocol, host):
    inp = f"protocol={protocol}\nhost={host}\n"
    p = subprocess.run(["git", "credential", "fill"],
                       input=inp, capture_output=True, text=True)
    out = {}
    for line in p.stdout.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip()
    return out

def main():
    cred = git_credential_fill("https", "gitee.com")
    user = cred.get("username")
    token = cred.get("password")
    if not token:
        print("NO_GITEE_TOKEN")
        sys.exit(2)
    print("GOT_TOKEN user=", user)

    # 1) create gitee repo via API
    api = "https://gitee.com/api/v5/user/repos"
    data = {
        "access_token": token,
        "name": "personal-blog-vue",
        "description": "Serverless personal blog (Vue3 + Vite + Supabase)",
        "private": False,
        "auto_init": False,
    }
    r = subprocess.run(["curl", "-s", "-X", "POST", api,
                        "-H", "Content-Type: application/json",
                        "-d", json.dumps(data)],
                       capture_output=True, text=True)
    try:
        j = json.loads(r.stdout)
    except Exception:
        j = {}
    if "id" in j or "full_name" in j:
        print("REPO_CREATED", j.get("full_name"))
    elif "already exists" in r.stdout or (j.get("message","").lower().find("exist")>=0):
        print("REPO_EXISTS")
    else:
        print("REPO_RESULT", r.stdout[:300])

    # 2) set GitHub secrets
    gh = r'"C:\Program Files\GitHub CLI\gh.exe"'
    env = dict(os.environ)
    env["PATH"] = env.get("PATH","") + ";C:\\Program Files\\GitHub CLI"
    repo = "Jesse-white-rs/personal-blog-vue"
    for name, val in [("GITEE_TOKEN", token), ("GITEE_USER", user or "rwg1940")]:
        p2 = subprocess.run(f'{gh} secret set {name} -b "{val}" --repo {repo}',
                            shell=True, capture_output=True, text=True, env=env)
        print("SECRET", name, "->", p2.stdout.strip() or p2.stderr.strip())

if __name__ == "__main__":
    main()
