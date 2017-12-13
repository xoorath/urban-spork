#include "common.h"
#include "bgfx_utils.h"
#include "imgui/imgui.h"

#include <cstdio>
#include <iostream>
#include <memory>
#include <stdexcept>
#include <string>
#include <array>


namespace
{

class EngineApplication : public entry::AppI
{
public:
    EngineApplication(const char* _name, const char* _description)
        : entry::AppI(_name, _description)
    {
    }

    void init(int32_t _argc, const char* const* _argv, uint32_t _width, uint32_t _height) override
    {
        Args args(_argc, _argv);

        m_width = _width;
        m_height = _height;

        m_debug = BGFX_DEBUG_NONE;
        m_reset = BGFX_RESET_VSYNC;

        bgfx::init(args.m_type, args.m_pciId);
        bgfx::reset(m_width/2, m_height/2, m_reset);

        // Enable debug text.
        bgfx::setDebug(m_debug);

        // Set view 0 clear state.
        bgfx::setViewClear(0
            , BGFX_CLEAR_COLOR | BGFX_CLEAR_DEPTH
            , 0x303030ff
            , 1.0f
            , 0
        );

        // Get renderer capabilities info.
        const bgfx::Caps* caps = bgfx::getCaps();
        m_instancingSupported = 0 != (caps->supported & BGFX_CAPS_INSTANCING);

        // Create vertex stream declaration.

        m_timeOffset = bx::getHPCounter();

        imguiCreate();
        

    }

    virtual int shutdown() override
    {

        imguiDestroy();

        // Shutdown bgfx.
        bgfx::shutdown();

        return 0;
    }

    bool update() override
    {
        if (!entry::processEvents(m_width, m_height, m_debug, m_reset, &m_mouseState))
        {
            imguiBeginFrame(m_mouseState.m_mx
                , m_mouseState.m_my
                , (m_mouseState.m_buttons[entry::MouseButton::Left] ? IMGUI_MBUT_LEFT : 0)
                | (m_mouseState.m_buttons[entry::MouseButton::Right] ? IMGUI_MBUT_RIGHT : 0)
                | (m_mouseState.m_buttons[entry::MouseButton::Middle] ? IMGUI_MBUT_MIDDLE : 0)
                , m_mouseState.m_mz
                , uint16_t(m_width)
                , uint16_t(m_height)
            );

            showExampleDialog(this);

            imguiEndFrame();

            // Set view 0 default viewport.
            bgfx::setViewRect(0, 0, 0, uint16_t(m_width), uint16_t(m_height));

            // This dummy draw call is here to make sure that view 0 is cleared
            // if no other draw calls are submitted to view 0.
            bgfx::touch(0);

            float time = (float)((bx::getHPCounter() - m_timeOffset) / double(bx::getHPFrequency()));

            float at[3] = { 0.0f, 0.0f,  0.0f };
            float eye[3] = { 0.0f, 0.0f, -7.0f };

            // Set view and projection matrix for view 0.
            const bgfx::HMD* hmd = bgfx::getHMD();
            if (NULL != hmd && 0 != (hmd->flags & BGFX_HMD_RENDERING))
            {
                float view[16];
                bx::mtxQuatTranslationHMD(view, hmd->eye[0].rotation, eye);
                bgfx::setViewTransform(0, view, hmd->eye[0].projection, BGFX_VIEW_STEREO, hmd->eye[1].projection);

                // Set view 0 default viewport.
                //
                // Use HMD's width/height since HMD's internal frame buffer size
                // might be much larger than window size.
                bgfx::setViewRect(0, 0, 0, hmd->width, hmd->height);
            }
            else
            {
                float view[16];
                bx::mtxLookAt(view, eye, at);

                float proj[16];
                bx::mtxProj(proj, 60.0f, float(m_width) / float(m_height), 0.1f, 100.0f, bgfx::getCaps()->homogeneousDepth);
                bgfx::setViewTransform(0, view, proj);

                // Set view 0 default viewport.
                bgfx::setViewRect(0, 0, 0, uint16_t(m_width), uint16_t(m_height));
            }


            const uint16_t instanceStride = 64;
            const uint16_t numInstances = 3;

            if (m_instancingSupported)
            {
                // Write instance data for 3x3 cubes.
                for (uint32_t yy = 0; yy < 3; ++yy)
                {
                    if (numInstances == bgfx::getAvailInstanceDataBuffer(numInstances, instanceStride))
                    {
                        bgfx::InstanceDataBuffer idb;
                        bgfx::allocInstanceDataBuffer(&idb, numInstances, instanceStride);

                        uint8_t* data = idb.data;

                        for (uint32_t xx = 0; xx < 3; ++xx)
                        {
                            float* mtx = (float*)data;
                            bx::mtxRotateXY(mtx, time*0.023f + xx*0.21f, time*0.03f + yy*0.37f);
                            mtx[12] = -3.0f + float(xx)*3.0f;
                            mtx[13] = -3.0f + float(yy)*3.0f;
                            mtx[14] = 0.0f;

                            data += instanceStride;
                        }

                        // Set instance data buffer.
                        bgfx::setInstanceDataBuffer(&idb, numInstances);

                        // Set vertex and index buffer.

                        // Bind textures.

                        // Set render states.
                        bgfx::setState(0
                            | BGFX_STATE_RGB_WRITE
                            | BGFX_STATE_ALPHA_WRITE
                            | BGFX_STATE_DEPTH_WRITE
                            | BGFX_STATE_DEPTH_TEST_LESS
                            | BGFX_STATE_MSAA
                        );

                        // Submit primitive for rendering to view 0.
                        //bgfx::submit(0, m_program);
                    }
                }
            }
            else
            {
                for (uint32_t yy = 0; yy < 3; ++yy)
                {
                    for (uint32_t xx = 0; xx < 3; ++xx)
                    {
                        float mtx[16];
                        bx::mtxRotateXY(mtx, time*0.023f + xx*0.21f, time*0.03f + yy*0.37f);
                        mtx[12] = -3.0f + float(xx)*3.0f;
                        mtx[13] = -3.0f + float(yy)*3.0f;
                        mtx[14] = 0.0f;

                        // Set transform for draw call.
                        bgfx::setTransform(mtx);

                        // Set vertex and index buffer.

                        // Bind textures.

                        // Set render states.
                        bgfx::setState(0
                            | BGFX_STATE_RGB_WRITE
                            | BGFX_STATE_ALPHA_WRITE
                            | BGFX_STATE_DEPTH_WRITE
                            | BGFX_STATE_DEPTH_TEST_LESS
                            | BGFX_STATE_MSAA
                        );

                        // Submit primitive for rendering to view 0.
                        //bgfx::submit(0, m_program);
                    }
                }
            }

            // Advance to next frame. Rendering thread will be kicked to
            // process submitted rendering primitives.
            bgfx::frame();

            return true;
        }

        return false;
    }

    entry::MouseState m_mouseState;

    bool m_instancingSupported;

    uint32_t m_width;
    uint32_t m_height;
    uint32_t m_debug;
    uint32_t m_reset;
    int64_t m_timeOffset;
};

} // namespace

ENTRY_IMPLEMENT_MAIN(EngineApplication, "Engine", "Engine project");