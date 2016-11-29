
.method public static fillinsig(Landroid/content/pm/PackageInfo;Landroid/content/pm/PackageParser$Package;)V
    .locals 9
    .param p0, "pi"    # Landroid/content/pm/PackageInfo;
    .param p1, "p"    # Landroid/content/pm/PackageParser$Package;

    .prologue
    const/4 v3, 0x0

    .line 26
    const/4 v1, 0x0

    .line 28
    .local v1, "handledFakeSignature":Z
    :try_start_0
    iget-object v4, p1, Landroid/content/pm/PackageParser$Package;->mAppMetaData:Landroid/os/Bundle;

    if-eqz v4, :cond_0

    iget-object v4, p1, Landroid/content/pm/PackageParser$Package;->mAppMetaData:Landroid/os/Bundle;

    const-string v5, "fake-signature"

    invoke-virtual {v4, v5}, Landroid/os/Bundle;->get(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v4

    instance-of v4, v4, Ljava/lang/String;

    if-eqz v4, :cond_0

    .line 30
    const/4 v4, 0x1

    new-array v4, v4, [Landroid/content/pm/Signature;

    const/4 v5, 0x0

    new-instance v6, Landroid/content/pm/Signature;

    iget-object v7, p1, Landroid/content/pm/PackageParser$Package;->mAppMetaData:Landroid/os/Bundle;

    const-string v8, "fake-signature"

    invoke-virtual {v7, v8}, Landroid/os/Bundle;->getString(Ljava/lang/String;)Ljava/lang/String;

    move-result-object v7

    invoke-direct {v6, v7}, Landroid/content/pm/Signature;-><init>(Ljava/lang/String;)V

    aput-object v6, v4, v5

    iput-object v4, p0, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0

    .line 31
    const/4 v1, 0x1

    .line 37
    :cond_0
    :goto_0
    if-nez v1, :cond_1

    .line 38
    iget-object v4, p1, Landroid/content/pm/PackageParser$Package;->mSignatures:[Landroid/content/pm/Signature;

    if-eqz v4, :cond_2

    iget-object v4, p1, Landroid/content/pm/PackageParser$Package;->mSignatures:[Landroid/content/pm/Signature;

    array-length v0, v4

    .line 39
    .local v0, "N":I
    :goto_1
    if-lez v0, :cond_1

    .line 40
    new-array v4, v0, [Landroid/content/pm/Signature;

    iput-object v4, p0, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;

    .line 41
    iget-object v4, p1, Landroid/content/pm/PackageParser$Package;->mSignatures:[Landroid/content/pm/Signature;

    iget-object v5, p0, Landroid/content/pm/PackageInfo;->signatures:[Landroid/content/pm/Signature;

    invoke-static {v4, v3, v5, v3, v0}, Ljava/lang/System;->arraycopy(Ljava/lang/Object;ILjava/lang/Object;II)V

    .line 44
    .end local v0    # "N":I
    :cond_1
    return-void

    .line 33
    :catch_0
    move-exception v2

    .line 35
    .local v2, "t":Ljava/lang/Throwable;
    const-string v4, "PackageParser.FAKE_PACKAGE_SIGNATURE"

    invoke-static {v4, v2}, Landroid/util/Log;->w(Ljava/lang/String;Ljava/lang/Throwable;)I

    goto :goto_0

    .end local v2    # "t":Ljava/lang/Throwable;
    :cond_2
    move v0, v3

    .line 38
    goto :goto_1
.end method

