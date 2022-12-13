import numpy as np


# test_case = "1.8112933e-05 4.0843574e-05 -0.00011653048 0.00018353632 0.00010131358 -2.308801e-06 -0.00026998678 -0.00025507578 6.779687e-05 -7.39873e-05 0.00033242122 0.00042379432 4.4351655e-06 -0.0002445926 -0.00058210286 0.000525635 -0.00031023775 -0.00041485435 9.808375e-08 -9.948177e-06 2.8850824e-05 0.00022996255 -7.8141304e-05 0.00024888187 -4.6871846e-05 -0.00028500645 -0.00024736105 -0.00026994722 -0.00037142762 -7.3574054e-05 0.00047809762 -0.00018864979 0.00072934804 0.00013013766 -7.556391e-05 2.2464872e-06 -1.8111641e-06 -8.815143e-08 -0.00023877417 -9.949923e-05 -0.00020578301 -6.9195165e-05 -0.00028253265 0.00028360615 0.00023579694 -0.0002573272 -0.00036960273 0.0004434874 0.00013292268 0.00049680413 0.00031557123 0.0010770407 6.6957665e-07 4.148248e-05 -1.7122575e-05 -5.0042207e-05 -3.374486e-05 -0.00019507199 0.00027945984 -7.301134e-05 4.6159417e-05 4.7847145e-05 -0.00027664518 -0.0003019052 6.235561e-05 7.245577e-05 -0.00014025348 0.00067467574 -0.00061868934 -0.00015221321 -0.0003801083 -0.00039217144 6.7637247e-06 4.166815e-05 -3.164698e-05 -6.417101e-05 -2.0729925e-05 0.00016320619 4.3408113e-06 -0.000107530126 -0.00015871035 0.00017320194 0.00014013599 -6.8137083e-06 -0.00031351618 5.0046463e-05 0.00020352444 0.00014275032 -0.00031650104 -0.00015491477 -1.0316163e-05 4.4997912e-05 0.00014374501 9.285232e-05 0.00014255366 -2.976875e-05 -0.00020529891 -3.263916e-05 -0.00014653418 -0.000159914 -4.253618e-05 -0.00032225472 -5.7185236e-05 0.00034415498 0.00029448993 0.00064839184 0.0003417931 -0.00023627898 -3.6041572e-05 -3.7332164e-05 1.8718016e-05 -9.757479e-05 0.0001544904 4.3818643e-05 8.4845364e-05 -2.6074775e-05 -0.0003432408 0.00037458158 3.3981305e-05 -0.00013318054 -8.417483e-05 -0.00037297278 0.0003094677 -8.443151e-05 0.00028356595 0.0008254877 -5.4336833e-06 -3.0785563e-05 3.4554098e-05 3.6954956e-05 7.629955e-05 3.8922008e-05 -0.00010142107 -0.00019324769 -0.0003375951 -0.00036842038 -0.00025184528 -0.00015919919 7.476848e-05 0.0001842034 0.00011720615 0.00015586347 -0.00023383959 -0.0001244518 -1.7188273e-05 3.2161952e-05 -5.1353596e-05 0.00013265596 -0.00025056157 0.00013294535 -9.8542936e-05 2.8134968e-05 -0.00021290059 0.00023234022 -3.6666203e-05 0.00015468142 -0.00025538565 0.00060490915 -0.00042073094 0.0002316411 -0.0002442943 0.0003936762 3.7801726e-06 1.2205222e-05 3.7042297e-05 3.5040393e-05 9.28616e-05 5.6370263e-05 0.00014001149 0.00010193798 0.00015640739 0.0001706887 0.00013284814 0.000219774 0.00010828627 0.00022418774 0.00011113393 0.000167087 9.270788e-05 8.658019e-05 9.644525e-06 -4.07809e-05 -1.8860972e-05 7.8353296e-05 0.00017512921 -2.155214e-05 -5.579385e-05 -5.7372992e-05 7.6478354e-05 -8.346148e-05 7.476994e-05 8.7578796e-05 4.1401276e-05 -0.00042279932 -0.00024850492 8.507634e-05 0.0003097617 -0.00022089593 4.8154848e-06 2.1996972e-05 -1.7526716e-05 3.3227018e-06 0.00012992455 0.00018719367 0.000107054795 0.00014772518 0.00034253392 0.00037381018 0.0001925192 0.00016804236 0.0003595957 0.0003136656 1.0538264e-05 -7.905791e-05 0.00016708359 0.000110292734 1.0954286e-05 2.0188238e-05 -7.267503e-05 0.00016076515 -2.9609386e-05 0.00015998205 0.00011592107 -0.00011527299 -9.453003e-05 0.000103161416 0.00015022668 -0.00018195962 -0.00030732268 7.148338e-05 -0.00050988194 0.00032781588 -0.0001533449 -0.0002508944 -4.366831e-06 -2.2106665e-06 -1.5942966e-05 -2.199813e-05 -1.2221285e-05 -5.195075e-05 -1.2842834e-05 -6.045703e-05 -3.919068e-05 -4.2769123e-05 -7.878913e-05 -2.0159208e-05 -9.979646e-05 -2.9504792e-05 -6.976916e-05 -7.1914066e-05 -1.679168e-05 -0.00010001688 2.5679583e-06 -5.9850768e-06 1.4276866e-05 -1.6859774e-05 2.6775322e-05 -2.955784e-05 3.7498485e-05 -4.091315e-05 4.6923466e-05 -5.1207975e-05 5.3319054e-05 -5.8860824e-05 5.678008e-05 -6.464135e-05 5.3472373e-05 -6.439877e-05 4.5461173e-05 -5.8815916e-05 6.1271235e-06 -2.485958e-05 -1.9165538e-05 5.847604e-05 5.574532e-07 -7.599496e-05 3.522652e-05 9.1354756e-05 -8.17326e-05 -8.9195484e-05 0.00011905583 5.5294553e-05 -0.00014598497 1.345811e-06 0.0001854623 -8.6450156e-05 -0.00018882728 0.0001403342 8.739458e-06 1.9815354e-05 -7.019265e-05 2.7376753e-05 -0.00016043182 0.00010323488 3.769386e-05 6.5178654e-05 0.00014734517 -0.00016079903 -8.4942476e-05 -5.91675e-05 -0.00019831235 0.0003873167 -8.682797e-05 0.00031661856 -0.00015051257 -0.00020016651 8.192768e-06 4.224196e-05 4.557172e-07 9.649609e-05 -2.6651955e-05 9.676121e-05 -2.9435785e-05 5.0939463e-05 -2.0350442e-06 -2.220861e-06 6.63856e-05 -4.620492e-05 0.00018587655 -6.4343505e-05 0.0003060465 2.0556074e-06 0.00032085957 0.00018764524 -1.062256e-06 4.5020993e-06 0.00010085734 2.1605779e-06 -3.914039e-05 0.00021758437 7.4160314e-05 -5.618086e-05 4.7588397e-05 -5.193362e-05 7.321632e-05 -0.000116408366 -0.00041797568 9.4493254e-05 -6.852478e-06 -0.00045493804 -3.419684e-05 2.4329664e-05 -1.08253425e-05 -6.505038e-07 1.1882731e-05 -7.3758056e-05 2.2023094e-05 -2.3318602e-05 -0.00010993298 5.425056e-05 -9.269748e-05 -0.00010116155 7.07007e-05 -0.0001725602 -4.479462e-05 5.3168453e-05 -0.00023393067 5.3599535e-05 -4.9410673e-06 -0.00024794112 -6.1576457e-06 -2.35002e-05 1.676536e-05 5.952237e-05 1.7802042e-06 -8.0918886e-05 -3.1455096e-05 9.2570575e-05 7.536524e-05 -8.224673e-05 -0.000120640325 4.9374605e-05 0.00015544373 -4.297793e-06 -0.00018878083 -7.5623655e-05 0.00017850177 0.00014103328 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 -4.7922126e-06 1.3598761e-05 -2.3877601e-05 3.5439763e-05 -4.531326e-05 5.0206996e-05 -4.9126636e-05 4.459038e-05 -4.1698615e-05 4.5506054e-05 -5.811131e-05 7.7113364e-05 -9.644674e-05 0.000109395885 -0.00011240057 0.000107704895 -0.000103292856 0.00010975972 3.6409351e-06 -2.5162202e-05 4.4618486e-05 -3.905186e-05 1.9250258e-06 5.1379033e-05 -9.112765e-05 8.985868e-05 -3.9149785e-05 -4.2724492e-05 0.00011710611 -0.00014304175 9.8698205e-05 4.6474233e-06 -0.00012385669 0.00020126098 -0.00019112592 8.3391125e-05 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0"

test_case = "-0.0005073328 0.0003490945 0.00012460357 -0.0003514589 -0.000509502 -0.0010781202 -0.00044010952 6.3188374e-05 0.014141927 0.012249564 -0.039754707 -0.11335709 -0.2677775 -0.30426303 -0.29313877 -0.22686681 -0.13144213 -0.0943164 1.1411634e-05 -0.00030372752 -0.00015299933 0.00079404993 -0.0014434123 0.00056218426 8.80108e-05 0.0024121134 -0.0005206615 0.012988806 0.015608461 0.014065708 0.005820354 -0.011955359 0.018135766 0.0044353125 -0.0079918215 0.016321352 -0.0002771613 0.00022864222 0.0011330495 0.00071788253 0.00030256232 0.00038714363 -0.00086909987 -0.0019608648 -0.0038410476 -0.010528876 -0.004377112 0.01688812 0.019537054 0.0013258149 -0.012776019 -0.0077034747 -0.0073889606 -0.00021163956 -0.00017015214 0.00048538262 -0.00012543173 -0.0002744922 -0.0010700488 -0.00012687748 0.000535042 -9.876443e-05 0.0038217416 7.669325e-05 -0.01596926 0.032198377 -0.0092087425 -0.0049319793 0.005938053 -0.016835045 0.0012400374 -0.005172539 0.00021846266 0.00044088837 -0.00020182761 -0.00051336683 -1.82369e-05 0.0010120558 -0.0001745554 0.0005894426 -0.0011232588 -0.011708865 -0.0037497384 0.0007255097 0.009598683 0.005861317 -0.005300266 0.003906845 -0.0017058962 0.008768826 2.3171953e-05 -0.00015285262 -3.6684152e-05 0.0006055171 -0.00027675473 -0.0006637423 -0.0007898622 -0.00081567094 -0.0059614256 -0.010653965 0.0045488384 -0.006074358 0.0013766326 -0.004589767 0.0061501875 0.0061589987 -0.0033405884 -0.009094028 -0.0003270043 -0.0006149878 -0.00088954007 -6.637628e-05 -0.0001260135 -0.00035249087 0.0013707688 0.0005509546 0.0053750454 0.0012468613 0.027995963 -0.004473 -0.0037181703 -0.0020958018 -0.00048279247 -0.0013086712 0.0044067334 0.0052528465 -0.00042236835 -1.1538417e-05 -0.00011178717 0.00052851095 0.00016416001 0.00029469846 -0.0014153481 0.0022442576 -0.0034131026 0.010731683 0.012282137 -0.006258935 0.015183924 -0.007710459 0.001048361 0.0033335723 0.0076991683 0.0003894528 -0.00025827077 -0.0002933701 0.0005487038 -0.00048539782 -6.8721165e-05 -0.0004968806 0.00027581357 0.00032089587 0.000416863 -0.0046973894 -0.0025840614 0.0075202747 0.0013190547 -0.0018591774 -0.0017302956 0.005334531 0.0024875645 -5.306842e-05 1.0776173e-05 6.456723e-05 -0.00017854173 7.989457e-05 -0.00049804157 0.00012212447 4.4273736e-05 -0.00015499012 -0.0010642679 -0.0003351367 -0.0012184479 0.006007091 -0.00048370514 -0.0021405173 0.0006790197 0.0032622516 0.010828184 -0.0011903003 -0.00039421197 -0.00025684392 -2.9628362e-05 -0.00024503647 8.08865e-05 0.0004353928 -0.00021311908 0.00040112738 0.0031405329 -0.0057204105 -0.00975292 0.0053084684 -0.0010031838 0.018676417 0.0028444154 0.006468444 -0.002854989 -0.005349123 -0.0002520475 -0.00030620402 0.00014761537 0.0002316182 -0.000334795 -0.00017357421 0.0006404272 0.00066703506 -0.0014423348 0.0033502998 -0.0021222937 0.0012056896 -0.0054779225 0.0011478844 -0.0036104275 -0.006365704 0.008815246 0.00093138893 -0.00055290654 0.0002678563 0.00034118682 -0.0002861983 2.3177046e-05 -5.1935713e-05 0.0001206015 0.0003884954 0.0011153846 0.0012495067 0.0064996285 -0.0102636665 -0.003925444 -0.0048178136 -0.00090671435 0.0003478678 -0.0024605347 -0.0017435981 6.3975313e-06 -7.447009e-05 -3.4033124e-05 -8.9364585e-06 -0.00010946227 -0.0001425893 -0.0003563972 0.00029808306 -0.0040960303 0.0006243418 0.003825507 -0.00011053424 0.0032486888 0.00056721014 -0.0020867204 -0.006364493 0.0043805353 0.0018305316 3.459306e-05 -4.9131217e-05 3.1538955e-05 -3.1741027e-05 0.000112218404 -3.1539963e-05 0.00069521 -0.00023236792 0.0029758718 0.0031668453 -0.0011969816 -0.0003732857 -0.01140226 0.0017658251 0.004101406 -0.0012095781 -0.005924483 0.0024714174 0.00018527404 -0.00024022177 -9.960814e-05 0.00036544696 -6.499352e-05 -0.00044893866 5.8888843e-05 0.00026022166 -0.001413962 0.0030402385 -0.0033565646 0.000102145146 0.0036250064 -0.001844578 -0.00740728 -9.769946e-05 -0.0012044279 -0.002464028 -0.0002414339 4.2939326e-05 -0.00012732345 0.0009004854 -0.00034959448 0.00057318737 -0.00092634506 -0.00120726 0.00068735826 0.0024165087 -0.0019238584 -9.5220006e-05 0.0015538449 -0.0043679215 0.002237542 -0.00039254618 0.0022466087 0.0046385243 0.00019497992 0.000411609 1.8851599e-05 0.00054663257 -0.00013905132 0.00060286815 -8.462157e-05 -0.00024776458 0.00058423996 0.0017740561 -0.0023581556 0.0021467637 -6.327845e-05 9.586237e-05 0.003224201 -0.0010914268 -0.0020230452 -0.00039769668 9.4751886e-05 0.00020614217 -0.00028514836 0.00058841356 0.0010457854 -0.00051801687 0.00053025485 -0.0002546158 0.00036808493 -0.00080914906 0.0055066347 -0.00086042855 -0.00036665084 0.0015970222 -0.0010230386 -0.002868357 0.0003754797 0.00018060929 0.00017814146 -0.00011787135 -0.00020544467 0.000318851 -0.00038674736 -0.00018835746 0.00014468217 -0.001477516 -0.0021307152 0.0007708348 0.0024705206 -0.00069997896 -0.002101991 0.0026382408 0.0015363549 0.0012166256 0.0006045139 0.000113816306 -0.00017411211 -0.00025484362 0.000104353196 0.0003765764 4.6907837e-05 -0.00044099626 -0.00015924004 0.0007751055 0.0010094953 0.0035836825 0.0020610956 0.0009476139 -0.0011332865 -0.00051406934 -0.002033054 -0.0010545113 -0.00049896305 0.001737374 0 -0 0 -0 0 -0 0.00019188876 -0.0011141588 0.00094397186 0.0012302081 -0.0026898172 0.0014575399 5.134009e-05 3.647001e-05 -0.0020637128 0.0013640652 -0.0016822028 -0.00022623644 -0.00013538002 0.00018222095 -0.00024315383 0.00030300813 -0.00034245316 0.0003437011 -0.00016743575 0.00055695086 0.0012325415 -0.0017234238 -0.00081880594 -0.0009984054 0.0019065541 -0.00021835239 -0.0015773867 -0.0011272033 -0.00037647306 -0.0009073809 8.680875e-05 -0.00025100436 0.0003321066 -0.00027084484 4.9105147e-05 0.0002995756 -0.0003943285 0.00081929227 -9.044912e-05 0.0019215285 -0.0007438675 0.0023429934 -0.0006877965 0.0010358009 -0.00046831925 -0.0007113259 0.0001430143 -0.0009801299 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0 0 -0"

vals = []

for item in test_case.split(" "):
    vals.append(float(item))
print(len(vals))
output = ""
print(max(np.abs(vals)))
for num in vals:
    lmao = int(np.abs(num) * 2 ** 30)
    if (num < 0):
        hex_num = hex((2 << 32) - int(np.abs(num) * 2 ** 30))[2:].zfill(8)[0:8]
    else:
        hex_num = hex(int(num * 2 ** 30))[2:].zfill(8)[0:8]

    output += hex_num

print(len(output))


print(output)
print(len(output) * 4)